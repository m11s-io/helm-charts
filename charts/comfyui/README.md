# comfyui Helm Chart

[![Docker Pulls](https://img.shields.io/docker/pulls/m11s/comfyui.svg)](https://hub.docker.com/r/m11s/comfyui/)
[![Build](https://github.com/m11s-io/docker-images/actions/workflows/build.yaml/badge.svg)](https://github.com/m11s-io/docker-images/actions/workflows/build.yaml)

[ComfyUI](https://github.com/comfyanonymous/ComfyUI) is a modular, node-based visual AI engine — image, video, audio, and 3D generation, not just Stable Diffusion. Upstream publishes no official container image, so this chart deploys [m11s/comfyui](https://github.com/m11s-io/docker-images/tree/main/comfyui), built from ComfyUI source on a CUDA runtime base.

This chart targets a single GPU-bound replica per release; it does not include HPA, PodDisruptionBudget, or NetworkPolicy resources.

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

- Chart: [github.com/m11s-io/charts](https://github.com/m11s-io/charts)
- Image: [github.com/m11s-io/docker-images](https://github.com/m11s-io/docker-images/tree/main/comfyui)
- Upstream: [github.com/comfyanonymous/ComfyUI](https://github.com/comfyanonymous/ComfyUI)
