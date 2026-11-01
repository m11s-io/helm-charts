"""Run with python -m unittest discover -s charts/comfyui/tests -p 'test_*.py'."""
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import threading
import unittest
import zipfile
from http.server import BaseHTTPRequestHandler, HTTPServer

SCRIPT = Path(__file__).resolve().parents[1] / 'files/custom_nodes.py'

class CustomNodesTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        assert SCRIPT.exists(), 'custom-node installer is missing'
        spec = importlib.util.spec_from_file_location('custom_nodes', SCRIPT)
        cls.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(cls.module)

    def test_rejects_invalid_repository_configuration(self):
        valid = dict(name='ComfyUI-GGUF', repository='https://github.com/city96/ComfyUI-GGUF.git', revision='a' * 40)
        for change in ({'name': '../escape'}, {'revision': 'main'}, {'repository': 'https://user:secret@example.com/repo'}, {'repository': 'file:///tmp/repo'}, {'requirements': '../requirements.txt'}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                self.module.validate_repositories([valid | change])
        with self.assertRaises(ValueError):
            self.module.validate_repositories([valid, valid])
        with self.assertRaises(ValueError):
            self.module.validate_repositories([])
        self.module.validate_repositories([valid])

    def test_checkout_is_pinned_and_requirements_cannot_escape_repository(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = root / 'source'
            subprocess.run(['git', 'init', '-q', str(source)], check=True)
            subprocess.run(['git', '-C', str(source), 'config', 'user.email', 'test@example.com'], check=True)
            subprocess.run(['git', '-C', str(source), 'config', 'user.name', 'Test'], check=True)
            (source / 'value').write_text('first')
            subprocess.run(['git', '-C', str(source), 'add', '.'], check=True)
            subprocess.run(['git', '-C', str(source), 'commit', '-qm', 'first'], check=True)
            revision = subprocess.check_output(['git', '-C', str(source), 'rev-parse', 'HEAD'], text=True).strip()
            (source / 'value').write_text('second')
            subprocess.run(['git', '-C', str(source), 'commit', '-qam', 'second'], check=True)
            target = root / 'target'
            self.module.checkout(str(source), revision, target)
            self.assertEqual((target / 'value').read_text(), 'first')
            (target / 'requirements.txt').symlink_to(root / 'outside')
            with self.assertRaises(ValueError):
                self.module.requirements_path(target, 'requirements.txt')

    def test_shared_environment_inherits_base_packages_and_cleans_retry(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / 'extensions'
            root.mkdir()
            (root / 'stale').write_text('old')
            python = self.module.prepare_environment(root)
            self.assertFalse((root / 'stale').exists())
            baseline = self.module.distributions(sys.executable)
            self.assertEqual(self.module.distributions(python), baseline)
            self.assertIn('pip==', (root / 'constraints.txt').read_text())
            wheel = Path(tmp) / 'pip-999.0-py3-none-any.whl'
            with zipfile.ZipFile(wheel, 'w') as archive:
                archive.writestr('pip-999.0.dist-info/METADATA', 'Metadata-Version: 2.1\nName: pip\nVersion: 999.0\n')
                archive.writestr('pip-999.0.dist-info/WHEEL', 'Wheel-Version: 1.0\nGenerator: test\nRoot-Is-Purelib: true\nTag: py3-none-any\n')
                archive.writestr('pip-999.0.dist-info/RECORD', '')
            result = subprocess.run([python, '-m', 'pip', 'install', '--no-index', '-c', str(root / 'constraints.txt'), str(wheel)], capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('ResolutionImpossible', result.stderr)
            self.assertEqual(self.module.distributions(python), baseline)
            # The same local wheel is installable without constraints, so network
            # failure or an unavailable version cannot explain the rejection.
            result = subprocess.run([python, '-m', 'pip', 'install', '--no-index', str(wheel)], capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(self.module.distributions(python)['pip']['version'], '999.0')
            (root / 'venv' / 'stale').write_text('old')
            self.module.prepare_environment(root)
            self.assertFalse((root / 'venv' / 'stale').exists())

    def test_readiness_requires_classes_even_when_http_is_healthy(self):
        class Handler(BaseHTTPRequestHandler):
            nodes = {}
            def do_GET(self):
                self.send_response(200)
                self.end_headers()
                self.wfile.write(json.dumps(self.nodes if self.path == '/object_info' else {}).encode())
            def log_message(self, *args):
                pass
        server = HTTPServer(('127.0.0.1', 0), Handler)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            url = f'http://127.0.0.1:{server.server_port}'
            with self.assertRaises(RuntimeError):
                self.module.check_ready(url, ['UnetLoaderGGUF'])
            Handler.nodes = {'UnetLoaderGGUF': {}}
            self.module.check_ready(url, ['UnetLoaderGGUF'])
        finally:
            server.shutdown()
            server.server_close()
            thread.join()

if __name__ == '__main__':
    unittest.main()
