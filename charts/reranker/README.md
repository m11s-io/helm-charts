# reranker

Deploys an OpenVINO Model Server reranker with an optional Jina-compatible
`POST /v1/rerank` adapter. The tested default is
`OpenVINO/Qwen3-Reranker-0.6B-seq-cls-fp16-ov` on CPU.

```sh
helm install qwen3-reranker m11s/reranker --namespace rerank
```

The ClusterIP Service exposes the Jina-compatible API on port 8080 and native
OVMS `/v3/rerank` on port 8000. Native Qwen clients must apply Qwen's prompt
template themselves; the proxy does that for Jina-compatible clients.

The proxy is enabled by default and can be disabled with
`--set proxy.enabled=false`. Persistence defaults to a 2Gi ReadWriteOnce PVC.
Set `persistence.existingClaim`, or use `persistence.enabled=false` for an
ephemeral model cache. The chart does not create a Namespace.

Key values:

| Value | Default | Purpose |
| --- | --- | --- |
| `model.source` | `OpenVINO/Qwen3-Reranker-0.6B-seq-cls-fp16-ov` | Downloaded model |
| `model.device` | `CPU` | OpenVINO target device |
| `runtime.image.repository` | `openvino/model_server` | OVMS image |
| `proxy.enabled` | `true` | Enable Jina-compatible adapter |
| `proxy.image.repository` | `m11s/rerank-proxy` | Adapter image |
| `persistence.size` | `2Gi` | Model-cache capacity |
| `persistence.storageClass` | `""` | Storage class |
| `service.jina.port` | `8080` | Jina-compatible port |
| `service.ovms.port` | `8000` | Native OVMS port |

See [values.yaml](values.yaml) for all configuration and defaults.
