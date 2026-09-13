# ovms

Deploys [OpenVINO Model Server](https://github.com/openvinotoolkit/model_server)
(OVMS) for any task it supports. The model is pulled from HuggingFace at startup
and cached on a PVC.

```sh
helm install qwen3-reranker m11s/ovms --namespace rerank \
  --set model.source=OpenVINO/Qwen3-Reranker-0.6B-seq-cls-fp16-ov \
  --set model.task=rerank
```

`model.source` is required and has no default — the chart is model-agnostic and
fails to render without one. The release name identifies the model; the chart
identifies the runtime.

## Tasks

`model.task` selects which OVMS graph is built, and therefore which endpoint is
served on `service.port`:

| `model.task` | Endpoint |
| --- | --- |
| `rerank` | `POST /v3/rerank` |
| `embeddings` | `POST /v3/embeddings` |
| `text_generation` | `POST /v3/chat/completions`, `POST /v3/completions` |

Other values are passed through verbatim. Health lives at `/v2/health/ready`
and `/v2/health/live` (KServe v2 API) regardless of task.

Native OVMS clients must apply the model's own prompt template themselves. This
matters for instruction-tuned rerankers such as Qwen3-Reranker, which expect a
chat template around the query and each document — see
[`rerank-proxy`](https://github.com/m11s-io/rerank-proxy) for a Jina-compatible
adapter that does this.

## Devices

`model.device` is an **OpenVINO** target: `CPU`, `GPU` (Intel iGPU or Arc), `NPU`,
or the `AUTO`/`MULTI`/`HETERO` meta-plugins. There is no CUDA target — OpenVINO
does not run on NVIDIA GPUs.

Key values:

| Value | Default | Purpose |
| --- | --- | --- |
| `model.source` | _(required)_ | HuggingFace repo id to pull |
| `model.name` | `model.source` | Name clients address the model by |
| `model.task` | `rerank` | OVMS task graph to build |
| `model.device` | `CPU` | OpenVINO target device |
| `runtime.image.repository` | `openvino/model_server` | OVMS image |
| `runtime.extraArgs` | `[]` | Extra CLI args appended verbatim |
| `persistence.size` | `2Gi` | Model-cache capacity |
| `persistence.existingClaim` | `""` | Reuse an existing PVC |
| `service.port` | `8000` | Service port for the REST API |

A cold start downloads the model before serving, so `runtime.startupProbe`
allows up to 30 minutes by default. Set `persistence.enabled=false` for an
ephemeral cache, at the cost of re-downloading on every restart.

The chart does not create a Namespace.

See [values.yaml](values.yaml) for all configuration and defaults.
