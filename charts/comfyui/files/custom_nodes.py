"""Install Helm-declared custom nodes without changing the image environment."""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import urllib.parse
import urllib.request
import venv

ROOT = Path('/opt/comfyui-extensions')
CONFIG = Path('/etc/comfyui-extensions/config.json')


def validate_repositories(repositories):
    if not repositories:
        raise ValueError('customNodes requires at least one repository')
    names = set()
    for repo in repositories:
        name = repo['name']
        if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_-]*', name) or name.casefold() in names:
            raise ValueError('repository names must be unique safe directory names')
        names.add(name.casefold())
        url = urllib.parse.urlsplit(repo['repository'])
        if url.scheme != 'https' or not url.hostname or url.username or url.password or url.query or url.fragment:
            raise ValueError(f'{name}: repository must be an HTTPS URL without credentials')
        if not re.fullmatch(r'[a-fA-F0-9]{40}', repo['revision']):
            raise ValueError(f'{name}: revision must be a full commit hash')
        requirements = repo.get('requirements', '')
        if requirements and (Path(requirements).is_absolute() or '..' in Path(requirements).parts):
            raise ValueError(f'{name}: requirements must be a contained relative path')


def checkout(repository, revision, target):
    subprocess.run(['git', 'init', '-q', str(target)], check=True)
    subprocess.run(['git', '-C', str(target), 'fetch', '--quiet', '--depth', '1', '--', repository, revision], check=True)
    subprocess.run(['git', '-C', str(target), 'checkout', '--quiet', '--detach', 'FETCH_HEAD'], check=True)
    head = subprocess.check_output(['git', '-C', str(target), 'rev-parse', 'HEAD'], text=True).strip()
    if head.lower() != revision.lower():
        raise RuntimeError(f'{target.name}: fetched revision does not match requested commit')


def requirements_path(repository, relative):
    path = (repository / relative).resolve()
    if not path.is_relative_to(repository.resolve()):
        raise ValueError(f'{repository.name}: requirements escape repository')
    if not path.is_file():
        raise ValueError(f'{repository.name}: requirements file is missing')
    return path


def distributions(python):
    code = """
import importlib.metadata as m, json, re
result = {}
for d in m.distributions():
    name = re.sub(r'[-_.]+', '-', d.metadata['Name']).lower()
    result.setdefault(name, {'version': d.version, 'location': str(d.locate_file('').resolve())})
print(json.dumps(result))
"""
    return json.loads(subprocess.check_output([str(python), '-c', code], text=True))


def prepare_environment(root):
    # This directory is a dedicated emptyDir, never a user/model volume.
    if root.exists():
        shutil.rmtree(root / 'venv', ignore_errors=True)
        for child in root.iterdir():
            if child.is_dir() and not child.is_symlink():
                shutil.rmtree(child)
            else:
                child.unlink()
    root.mkdir(parents=True, exist_ok=True)
    baseline = distributions(sys.executable)
    venv.EnvBuilder(system_site_packages=True, with_pip=False, symlinks=True).create(root / 'venv')
    python = root / 'venv/bin/python'
    # Nested venvs inherit the base interpreter, not the image's /opt/venv.
    import sysconfig
    parent_paths = list(dict.fromkeys([sysconfig.get_path('purelib'), sysconfig.get_path('platlib')]))
    child_site = subprocess.check_output([str(python), '-c', "import sysconfig; print(sysconfig.get_path('purelib'))"], text=True).strip()
    Path(child_site, 'image-packages.pth').write_text('\n'.join(parent_paths) + '\n')
    inherited = distributions(python)
    if inherited != baseline:
        raise RuntimeError('shared environment does not expose the exact image distributions')
    (root / 'constraints.txt').write_text(''.join(f"{name}=={value['version']}\n" for name, value in sorted(baseline.items())))
    (root / 'baseline.json').write_text(json.dumps(baseline))
    return str(python)


def install(config, root):
    repositories = config['repositories']
    validate_repositories(repositories)
    for repo in repositories:
        if (Path('/app/custom_nodes') / repo['name']).exists():
            raise ValueError(f"{repo['name']}: already bundled in image; use a generic image")
    python = prepare_environment(root)
    requirements = []
    for repo in repositories:
        print(f"[custom-nodes] fetch {repo['name']} revision={repo['revision']}", flush=True)
        target = root / 'custom_nodes' / repo['name']
        target.parent.mkdir(exist_ok=True)
        checkout(repo['repository'], repo['revision'], target)
        if repo.get('requirements'):
            requirements += ['-r', str(requirements_path(target, repo['requirements']))]
    if requirements:
        print('[custom-nodes] install requirements with image constraints', flush=True)
        # PIP_CONSTRAINT from the image remains active in addition to this snapshot.
        subprocess.run([python, '-m', 'pip', 'install', '--disable-pip-version-check', '--no-cache-dir',
                        '--only-binary=comfy-kitchen,comfy-aimdo', '-c', str(root / 'constraints.txt'), *requirements], check=True)
    baseline = json.loads((root / 'baseline.json').read_text())
    installed = distributions(python)
    for name, expected in baseline.items():
        if installed.get(name) != expected:
            raise RuntimeError(f'{name}: plugin installation replaced an image package')
    subprocess.run([python, '-m', 'pip', 'check'], check=True)
    paths = {'helm_custom_nodes': {'custom_nodes': str(root / 'custom_nodes')}}
    (root / 'extra_paths.yaml').write_text(json.dumps(paths))
    print('[custom-nodes] installation complete', flush=True)


def check_ready(url, expected):
    with urllib.request.urlopen(url + '/system_stats', timeout=2) as response:
        json.load(response)
    with urllib.request.urlopen(url + '/object_info', timeout=2) as response:
        nodes = json.load(response)
    missing = sorted(set(expected) - nodes.keys())
    if missing:
        raise RuntimeError('missing node classes: ' + ', '.join(missing))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['install', 'run', 'ready'])
    parser.add_argument('--config', type=Path, default=CONFIG)
    parser.add_argument('--root', type=Path, default=ROOT)
    args, runtime_args = parser.parse_known_args()
    config = json.loads(args.config.read_text())
    if args.action == 'install':
        install(config, args.root)
    elif args.action == 'ready':
        expected = [node for repo in config['repositories'] for node in repo.get('expectedNodes', [])]
        check_ready(config['url'], expected)
    else:
        python = str(args.root / 'venv/bin/python')
        environment = os.environ.copy()
        environment['PATH'] = str(args.root / 'venv/bin') + os.pathsep + environment['PATH']
        environment['VIRTUAL_ENV'] = str(args.root / 'venv')
        if runtime_args[:1] == ['--']:
            runtime_args = runtime_args[1:]
        os.execve(python, [python, '/app/main.py', *runtime_args, '--extra-model-paths-config', str(args.root / 'extra_paths.yaml')], environment)


if __name__ == '__main__':
    try:
        main()
    except (ValueError, RuntimeError, subprocess.CalledProcessError, OSError) as error:
        print(f'[custom-nodes] {error}', file=sys.stderr)
        sys.exit(1)
