# Helm-managed ComfyUI custom nodes

## Intent and scope

Allow operators to select pinned custom-node repositories through ComfyUI Helm
values, including GGUF and Krea 2 conditioning extensions, without rebuilding the
application image for each selection. The user selected the init-container
approach. This document proposes the detailed implementation for approval.

The feature is opt-in. Existing image, command, probes, persistence, and bundled
plugins retain their current behavior when disabled. This change does not deploy
to a cluster, publish images, or migrate the existing GGUF deployment.

## Approaches

- Image bundling remains supported and provides offline, prevalidated startup,
  but requires a rebuild for each plugin change.
- Main-container startup installation shares the application's Python environment,
  but couples installation and application execution and encourages mutation of
  the base environment.
- Selected: an init container using the exact workload image installs repositories
  and an additional Python environment into a shared ephemeral volume. ComfyUI
  starts only after installation completes. Each new Pod needs network access.

## Values and ownership

Add `customNodes.enabled` (default false), `customNodes.repositories` (default
empty), init-container resources, and a dedicated installer environment mapping
for package-index/proxy configuration. Repository entries declare a unique safe
directory name, HTTPS Git repository URL, full 40-character commit revision,
optional relative requirements-file path, and expected node class names.

An omitted requirements path means no additional Python requirements. No implicit
execution of `install.py`, shell hooks, submodule initialization, Manager, or
automatic repository updates. Plugins may execute their normal upstream
prestartup/import code when ComfyUI starts. Plugins needing OS packages must use
an image already containing them.

Use a ConfigMap for structured installer input and Python installer code; never
interpolate repository values into shell code. Validate names, duplicate names,
commit hashes, and path containment. An enabled empty repository list is invalid.
Repository URLs cannot contain credentials. Private-repository authentication is
outside the first version; package/proxy credentials use existing Secrets through
explicit secret references rather than plaintext values.

## Installation and Python environment

Use the workload image and non-root pod security context in a regular init
container. It requires no GPU access and must not import GPU model modules.
Share an `emptyDir` at a dedicated path such as `/opt/comfyui-extensions`.
The installer cleans only its own generated directories before each retry;
`emptyDir` survives container restarts within a Pod.

Fetch each requested revision and verify the resolved HEAD equals the requested
commit. Reject a repository directory already present in the image's default
custom-node directory rather than loading two copies (notably bundled GGUF).
Fetch failures stop installation with the repository name and operation logged.

Create a venv with `--system-site-packages` using the workload Python. It
must explicitly expose `/opt/venv` site-packages: a nested venv can
otherwise inherit only the interpreter's base environment, not the parent venv.
Derive the parent site-packages path from the workload interpreter and add it via
a .pth file in the shared environment. Verify visibility using package metadata
before dependency installation. This behavior requires a real-image spike before
the implementation is accepted.

Snapshot all installed base distribution versions into generated constraints,
combine with the image's existing constraints, and install all declared
requirements in one pip invocation. Base package replacements are unsupported:
incompatibilities fail with an actionable error. Verify base package origins and
versions remain unchanged, and run dependency checks. Do not copy or reinstall
Torch/CUDA packages. The shared environment and the image must use the same Python
ABI and image filesystem paths. Replacing the image recreates the Pod and rebuilds
the environment.

Runtime executes ComfyUI through the shared environment's Python, prepends its
bin directory to PATH, and preserves the existing listen/port arguments. Register
the managed repository directory through `--extra-model-paths-config`; upstream
supports the `custom_nodes` key. Preserve the default `/app/custom_nodes` directory
and existing extra path configuration. Do not mount over built-in plugin paths or
change the application base directory. The supported image contract is the
current m11s image with application `/app/main.py` and Python `/opt/venv/bin/python`;
support for arbitrary image layouts is out of scope.

## Lifecycle and failure behavior

Checksum installer configuration/code in Pod annotations to trigger a rollout
when repositories, revisions, expected classes, or installer behavior change.
Helm rollback recreates the desired installation from its recorded values.
Keep plugin code/dependencies ephemeral; do not add a plugin PVC or cache in v1.

Missing plugin requirements, conflicting base dependencies, invalid checkouts,
or duplicate bundled repositories fail the init container. Logs identify the
phase and plugin without exposing credentials.

Upstream can start its HTTP server despite plugin import failure. When expected
node classes are configured, extend readiness checks to query
`/object_info` and require those classes. Preserve ordinary HTTP startup and liveness behavior;
missing classes should not induce continuous liveness restarts. Existing
custom probe overrides need an explicit documented interaction rather than being
silently overwritten. Detailed probe composition is left to implementation.

## Verification and acceptance

First run an isolated real-image spike to establish shared-environment visibility,
non-root installation, parent package preservation, and GGUF loading without
copying Torch. A failed spike revises the design before production code proceeds.

Chart tests cover disabled output, same-image init container, shared mounts,
security context, configuration checksum, input rejection, and probes. Installer
tests cover pinned checkouts, retries, requirement conflicts, and base-package
preservation using small local fixtures. Run schema generation, chart lint,
rendering, and repository-required tests.

Validate GGUF and the conditioning plugin against the selected generic image in
an isolated runtime; check expected classes in `/object_info`. GPU workflow
execution, if needed, must use an explicitly selected test environment. No cluster
mutation is part of design approval.

## Tradeoffs and remaining implementation choices

Source commits are pinned, but transitive plugin dependencies are not a complete
lockfile; identical values can resolve newer compatible packages. Strict artifact
reproducibility and network-independent startup still require an image build.
An unavailable package index or Git host blocks new Pod startup. Resources,
timeouts, and clean log wording are routine implementation choices.
