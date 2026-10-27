# Timestral

Deploys the Timestral forecasting API as a single Kubernetes Deployment with an internal ClusterIP Service. The process loads one checkpoint during startup and exposes forecasts on port 8000.

## Release gate

The chart defaults make local rendering and CI validation possible. The image tags follow upstream Timestral `1.0.0`; each image build verifies that version against the installed package metadata. This does not mean the image has been published. Before a release deployment, publish the matching CPU or CUDA image and set `image.digest` to its verified `sha256:` digest. When `image.digest` is set, it takes precedence over `image.tag`. Do not add a registry or GitOps release reference until both the image digest and chart package have been published and reviewed.

The chart defaults to Timestral-209M at pinned revision `9874d252ab0aae16f7f7c999f98f98d6ad7d8365`. The image version identifies the inference package; choose the checkpoint with `model.id` and `model.revision`. The same CPU or CUDA image can load any compatible Timestral size. For example, select Timestral-123M with:

```yaml
model:
  id: mistralai/Timestral-123M
  revision: 5a147287addda85f6acd8da3fb8858fe9af7e8f7
```

Keep the model revision pinned so restarts use the same weights.

## CPU

```yaml
image:
  repository: m11s/timestral
  tag: 1.0.0-cpu
  digest: sha256:REPLACE_WITH_PUBLISHED_DIGEST
model:
  device: cpu
runtime:
  resources:
    requests:
      cpu: "2"
      memory: 2Gi
    limits:
      memory: 4Gi
persistence:
  enabled: true
  size: 2Gi
```

## CUDA

Setting `model.device: cuda` alone does not allocate a GPU. Select compatible NVIDIA nodes and request a GPU resource. Adjust labels and tolerations to match the cluster's device plugin and node policy.

```yaml
image:
  repository: m11s/timestral
  tag: 1.0.0-cuda
  digest: sha256:REPLACE_WITH_PUBLISHED_DIGEST
model:
  device: cuda
runtime:
  resources:
    requests:
      cpu: "4"
      memory: 8Gi
    limits:
      memory: 16Gi
      nvidia.com/gpu: 1
nodeSelector:
  nvidia.com/gpu.present: "true"
# tolerations:
#   - key: nvidia.com/gpu
#     operator: Exists
#     effect: NoSchedule
```

## Cache and credentials

The chart creates a 2 GiB `ReadWriteOnce` PVC by default and uses a `Recreate` rollout strategy so two pods do not contend for a single-writer cache. Set `persistence.existingClaim` to use an existing claim; set `persistence.enabled: false` for an ephemeral cache. The cache is mounted at `/models`, and `HF_HOME` is set to `/models/huggingface`. `/tmp` is an `emptyDir`, allowing the container to run with a read-only root filesystem. The API binds to port 8000; the container port is fixed while `service.port` can change the in-cluster Service port.

Use `runtime.extraEnv` to reference a Secret for gated model access when required. Do not place tokens in Helm values committed to Git:

```yaml
runtime:
  extraEnv:
    - name: HF_TOKEN
      valueFrom:
        secretKeyRef:
          name: timestral-huggingface
          key: token
```

The pod does not mount a service account token. It runs as nonroot, drops Linux capabilities, and disables privilege escalation by default.

## API limits and probes

`runtime.limits` maps to the service environment contract:

| Value | Environment variable | Default |
|---|---|---:|
| `maxRequestBytes` | `MAX_REQUEST_BYTES` | 8388608 |
| `maxBatchSize` | `MAX_BATCH_SIZE` | 8 |
| `maxRowsPerSeries` | `MAX_ROWS_PER_SERIES` | 32 |
| `maxContextSteps` | `MAX_CONTEXT_STEPS` | 32768 |
| `maxPredictionLength` | `MAX_PREDICTION_LENGTH` | 1024 |
| `maxOutputElements` | `MAX_OUTPUT_ELEMENTS` | 1000000 |

Startup probes allow 30 minutes for a cold checkpoint download (`periodSeconds: 10`, `failureThreshold: 180`). Readiness uses `/readyz` and stays false until model initialization completes. Liveness uses `/healthz` to check process health without running inference. Keep the startup window long enough for your storage and network conditions.
