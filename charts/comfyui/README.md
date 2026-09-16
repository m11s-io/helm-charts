# comfyui Helm Chart

[![Docker Pulls](https://img.shields.io/docker/pulls/m11s/comfyui.svg)](https://hub.docker.com/r/m11s/comfyui/)
[![Build](https://github.com/m11s-io/docker-images/actions/workflows/build.yaml/badge.svg)](https://github.com/m11s-io/docker-images/actions/workflows/build.yaml)

[ComfyUI](https://github.com/comfyanonymous/ComfyUI) is a modular, node-based visual AI engine — image, video, audio, and 3D generation, not just Stable Diffusion. Upstream publishes no official container image, so this chart deploys [m11s/comfyui](https://github.com/m11s-io/docker-images/tree/main/comfyui), built from ComfyUI source on a CUDA runtime base.

This chart targets a single GPU-bound replica per release; it does not include HPA or PodDisruptionBudget resources. `strategy` defaults to `Recreate` rather than Kubernetes' default `RollingUpdate`, since GPU nodes typically expose exactly one `nvidia.com/gpu` and RollingUpdate's create-before-destroy behavior deadlocks — the new pod can never schedule while the old one still holds the only GPU.

The chart's default GGUF image uses Python 3.14 and includes the pinned ComfyUI-GGUF extension. Python 3.14 is supported by ComfyUI and PyTorch, but community custom nodes may not yet support it; use a custom `image.tag` if a required node needs an older interpreter.

## Optional Comfy MCP HTTP service

Set `comfyMcp.enabled=true` to add the thin `m11s/comfy-mcp` image as a sidecar
in the ComfyUI Pod. It exposes native Streamable HTTP on port 8080 at `/mcp`
and reaches ComfyUI through both `COMFY_LOCAL_URL` and
`COMFYUI_URL`, set to `http://127.0.0.1:8188`. The first supports local
inspection; the second ensures workflow and job tools submit to the
colocated ComfyUI rather than Kubernetes' service-link environment. It does
not request another GPU or mount the models PVC.
`comfyMcp.httpRoute.enabled=true` adds a direct `/mcp` HTTPRoute backend with
no MCP proxy filter.

## Installation

```bash
helm repo add m11s https://m11s-io.github.io/helm-charts
helm repo update
helm install comfyui m11s/comfyui -n comfyui --create-namespace \
  --set runtimeClassName=nvidia \
  --set nodeSelector."workload\.example\.io/comfyui"=true \
  --set resources.limits."nvidia\.com/gpu"=1 \
  --set resources.requests."nvidia\.com/gpu"=1
```

GPU scheduling (`runtimeClassName`, `nodeSelector`, `tolerations`, `resources`) is left empty by default since it's cluster-specific — set it to match how your cluster labels and isolates GPU nodes.

## Configuration

| Parameter | Description | Default |
|---|---|---|
| `image.repository` | Container image repository | `m11s/comfyui` |
| `image.tag` | Image tag; defaults to the chart appVersion | `""` |
| `replicaCount` | Number of pod replicas | `1` |
| `strategy` | Deployment update strategy | `{type: Recreate}` |
| `service.type` | Kubernetes Service type | `ClusterIP` |
| `service.port` | Port the Service listens on | `8188` |
| `runtimeClassName` | Pod RuntimeClass; set to `nvidia` on clusters where GPU access requires it | `""` |
| `resources` | CPU/memory/GPU requests and limits (e.g. `nvidia.com/gpu: "1"`) | `{}` |
| `persistence.enabled` | Create (or reuse) a PVC for the models directory | `false` |
| `persistence.existingClaim` | Reuse an existing PVC instead of creating one | `""` |
| `persistence.storageClassName` | StorageClass for the created PVC | `""` |
| `persistence.accessMode` | PVC access mode | `ReadWriteOnce` |
| `persistence.size` | PVC storage request | `200Gi` |
| `persistence.mountPath` | Where the models volume is mounted | `/app/models` |
| `modelDownload.enabled` | Create a Job to download models into the persistent PVC | `false` |
| `modelDownload.image` | Optional downloader image; empty uses the ComfyUI workload image | `""` |
| `modelDownload.huggingFaceToken.existingSecret` | Optional existing Secret with an HF read token | `""` |
| `modelDownload.huggingFaceToken.key` | Key in that Secret containing the token | `token` |
| `modelDownload.backoffLimit` | Maximum downloader Job retries | `3` |
| `modelDownload.models` | Model entries with relative destination, HF repo/file/revision, and SHA-256 hash | `[]` |
| `modelDownload.resources` | CPU and memory requests/limits for the downloader Job; defaults reserve 512Mi and allow 5Gi for `hf_xet` buffers | `{requests: ..., limits: ...}` |
| `modelDownload.ttlSecondsAfterFinished` | Optional TTL for completed Jobs; unset by default for Argo CD reconciliation | `null` |
| `httpRoute.enabled` | Enable a Gateway API HTTPRoute | `false` |
| `httpRoute.parentRefs` | Gateways the HTTPRoute attaches to; required when enabled | `[]` |
| `httpRoute.hostnames` | Hostnames the HTTPRoute matches | `[]` |
| `nodeSelector` | Node labels to constrain scheduling | `{}` |
| `tolerations` | Tolerations, e.g. for a GPU node taint | `[]` |

## Persistence

Without `persistence.enabled`, downloaded models, LoRAs, and checkpoints do not survive pod restarts. The chart mounts a single PVC at `persistence.mountPath` (default `/app/models`); ComfyUI's `output`, `input`, and `user` directories stay on the container filesystem, since this chart targets one replica per release rather than a horizontally-scaled deployment.

```yaml
persistence:
  enabled: true
  storageClassName: local-path
  size: 200Gi
```

## Downloading models into the PVC

`modelDownload` renders a one-shot Kubernetes Job that uses the official
[`hf download` CLI](https://huggingface.co/docs/huggingface_hub/guides/cli#hf-download)
to fetch model files directly into the persistent models PVC. Each destination
is relative to `persistence.mountPath`; the Hub cache stays on that PVC so
interrupted downloads resume, and the cached blob is hard-linked into the
requested ComfyUI path only after its configured SHA-256 verifies. Pin every
`revision` to the source repository's 40-character commit SHA. The Job inherits
the chart's node selector, affinity, tolerations, and pod security context, so
it can safely share a node-local ReadWriteOnce models PVC with ComfyUI.

For private or gated repositories, or to use Hugging Face's authenticated rate
limit, create a [fine-grained read token](https://huggingface.co/docs/hub/security-tokens)
in a Kubernetes Secret outside Helm and configure its name and key. The token
is injected only into the downloader Job as `HF_TOKEN`.

```yaml
modelDownload:
  huggingFaceToken:
    existingSecret: comfyui-hf-token
    key: token
```

```yaml
persistence:
  enabled: true

modelDownload:
  enabled: true
  models:
    - destination: diffusion_models/example.safetensors
      repo: example-org/example-model
      revision: 0123456789abcdef0123456789abcdef01234567
      file: split_files/diffusion_models/example.safetensors
      sha256: 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
```

## Probes

ComfyUI's HTTP listener comes up before models finish loading, so probes use `/system_stats` rather than a bare TCP or `/` check. `startupProbe` is tuned for a multi-minute cold start (`failureThreshold: 30` at 10s intervals, ~5 minutes) so `livenessProbe` doesn't restart the pod mid model-load.

## Example: GPU node with dedicated model storage

```yaml
runtimeClassName: nvidia

nodeSelector:
  workload.example.io/comfyui: "true"

tolerations:
  - key: nvidia.com/gpu
    operator: Equal
    value: "true"
    effect: NoSchedule

resources:
  requests:
    cpu: "2"
    memory: 6Gi
    nvidia.com/gpu: "1"
  limits:
    memory: 10Gi
    nvidia.com/gpu: "1"

persistence:
  enabled: true
  storageClassName: local-path
  size: 200Gi
```

## Source

- Chart: [github.com/m11s-io/helm-charts](https://github.com/m11s-io/helm-charts)
- Image: [github.com/m11s-io/docker-images](https://github.com/m11s-io/docker-images/tree/main/comfyui)
- Upstream: [github.com/comfyanonymous/ComfyUI](https://github.com/comfyanonymous/ComfyUI)
