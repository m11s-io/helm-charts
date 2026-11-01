# ComfyUI custom nodes implementation plan

> **For agentic workers:** Use superpowers:executing-plans inline, as requested.

**Goal:** Install pinned ComfyUI plugins through Helm and retire the GGUF image variant.
**Architecture:** A same-image init container prepares a shared ephemeral Python environment and plugin directory. Runtime adds that environment and directory while preserving built-in nodes. GitOps selects GGUF explicitly on a generic image.
**Tech Stack:** Python standard library, pip/venv, Helm, Kubernetes, GitHub Actions.
**Spec:** ../specs/2026-11-01-comfyui-custom-nodes-design.md

## Global constraints
- Work directly on main; preserve unrelated changes; no cluster mutations or pushes.
- Pin repository commits and protect existing image distributions.
- Disabled feature preserves current runtime behavior.
- User additionally requested removal of the GGUF image build process.

## Review focus
- Nested venv sees parent packages without copying Torch.
- Container retry starts clean; plugin removal leaves no stale files.
- Conflicting requirements cannot replace base packages.
- Import failures keep readiness false without liveness restart loops.
- Generic image migration installs GGUF only once and uses a published digest.

### Task 1: Installer and image spike
Files: charts/comfyui/files/custom_nodes.py, charts/comfyui/tests/test_custom_nodes.py.
Interface: installer CLI takes JSON config and extension root; readiness CLI checks expected classes.
- [x] Add failing fixture-based tests for validation, checkout pinning, environment inheritance, constraints, retry cleanup, and HTTP readiness.
- [x] Implement installer with subprocess argument arrays and structured configuration.
- [x] Run installer tests.
- [x] Real-image non-root GGUF and Krea conditioning registration passed in GitHub Actions across separate installer/runtime containers.

### Task 2: Chart integration
Files: values.yaml, values.schema.json, templates/deployment.yaml, templates/custom-nodes-configmap.yaml, tests/custom-nodes_test.yaml, README.md, Chart.yaml, CI workflow.
Interface: customNodes enabled/repositories/resources/environment/envFrom; entries name/repository/revision/requirements/expectedNodes.
- [x] Write chart rendering tests and observe failure.
- [x] Implement ConfigMap, same-image init, mounts, command, PATH, readiness, and rollout checksum.
- [x] Generate schema and run chart tests/lint/rendering plus installer tests in CI.

### Task 3: Retire GGUF images and configure GitOps
Files: docker-images/comfyui/Dockerfile.gguf (delete), verify_image.py, README.md, scripts/test_comfyui_validation.py, .github/workflows/build.yaml; registry ComfyUI values/README.
- [x] Remove GGUF build/tag/filter/validation paths while preserving generic CUDA/ROCm validation.
- [x] Switch chart default to published generic CUDA image; configure pinned GGUF in deployment values.
- [x] Run docker-images test suite, workflow checks, registry layout/catalog checks, and render deployment values with the local chart.
- [x] Review whole change with a fresh reviewer, resolve material issues, report evidence and limitations.

## Progress
- Both repos switched to main. Helm repo fast-forwarded to existing origin/main; unrelated Renovate changes already present there. Original change preserved in a named stash before switching.
- Published generic image resolved to 0.43.0-cuda@sha256:35a3d64564919e45872c61cec4fc1d3a4cf8740cc32834056fe93ccaa6d66e5e.
- Ruling: proceed immediately after recording plan because user explicitly requested straight implementation on main.

## Verification record
- Chart unit tests: 37 passed; installer tests: 4 passed; image repository tests: 41 passed.
- Chart lint and rendering with PLT values passed. Shell integration-test syntax and workflow YAML parsing passed.
- Fresh reviewer found old GitOps chart version and a weak conflict test; both corrected. Conflict test now proves a local wheel installs unconstrained and is rejected with constraints.
- Runtime image pull failed during CUDA layer extraction: Docker Desktop reported read-only filesystem. The subsequent GitHub Actions runtime test passed across separate installer/runtime containers, registering both plugins. GPU inference remains a separate hardware check.
- Registry resource-layout check has existing errors in unrelated app/resource paths. Catalog rendering produced only the intended ComfyUI 0.14.0 change; check-rendered reports that uncommitted expected diff.
- Ruling: user expanded scope to publish ROCm normally on main; removed validation-only gating and documented backend selection. Hardware acceptance remains distinct from publishing.
- Ruling: plugin environment inherits base distributions explicitly via .pth, because nested venv system-site-packages alone is insufficient. Local fixture verifies exact metadata visibility and package origin preservation.
- No pushes, publication, or cluster deployments performed. Preserve unrelated working-tree edits and original named Renovate stash.

- Follow-up CI: the first real-container runtime check passed for both plugins. Installer unit CI exposed .pth processing and global-package inheritance differences; regression tests now cover an isolated parent venv, and the child explicitly inherits parent site directories without implicit global packages.
