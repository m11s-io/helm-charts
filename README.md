# m11s Helm Charts

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/m11s)](https://artifacthub.io/packages/search?org=m11s)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Release Charts](https://github.com/m11s-io/helm-charts/actions/workflows/release.yml/badge.svg)](https://github.com/m11s-io/helm-charts/actions/workflows/release.yml)

A collection of production-ready Helm charts for m11s platform services, published on [Artifact Hub](https://artifacthub.io/packages/search?org=m11s).

## Available Charts

| Chart | Artifact Hub | Description | Version |
|-------|--------------|-------------|---------|
| [comfyui](./charts/comfyui) | [![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/m11s)](https://artifacthub.io/packages/helm/m11s/comfyui) | Node-based, modular visual AI engine for GPU nodes | ![Version](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/m11s-io/helm-charts/main/charts/comfyui/Chart.yaml&label=&query=version&prefix=v) |
| [decap-cms](./charts/decap-cms) | [![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/m11s)](https://artifacthub.io/packages/helm/m11s/decap-cms) | Multi-tenant Decap CMS served by hostname | ![Version](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/m11s-io/helm-charts/main/charts/decap-cms/Chart.yaml&label=&query=version&prefix=v) |
| [dub](./charts/dub) | [![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/m11s)](https://artifacthub.io/packages/helm/m11s/dub) | Self-hosted link management platform | ![Version](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/m11s-io/helm-charts/main/charts/dub/Chart.yaml&label=&query=version&prefix=v) |
| [fider](./charts/fider) | [![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/m11s)](https://artifacthub.io/packages/helm/m11s/fider) | Self-hosted user feedback platform | ![Version](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/m11s-io/helm-charts/main/charts/fider/Chart.yaml&label=&query=version&prefix=v) |
| [ovms](./charts/ovms) | [![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/m11s)](https://artifacthub.io/packages/helm/m11s/ovms) | OpenVINO Model Server for rerank, embeddings, or text generation | ![Version](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/m11s-io/helm-charts/main/charts/ovms/Chart.yaml&label=&query=version&prefix=v) |
| [searxng](./charts/searxng) | [![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/m11s)](https://artifacthub.io/packages/helm/m11s/searxng) | Privacy-respecting metasearch engine | ![Version](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/m11s-io/helm-charts/main/charts/searxng/Chart.yaml&label=&query=version&prefix=v) |
| [timestral](./charts/timestral) | [![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/m11s)](https://artifacthub.io/packages/helm/m11s/timestral) | Mistral Timestral time-series forecasting API for CPU or NVIDIA CUDA | ![Version](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/m11s-io/helm-charts/main/charts/timestral/Chart.yaml&label=&query=version&prefix=v) |
| [shlink](./charts/shlink) | [![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/m11s)](https://artifacthub.io/packages/helm/m11s/shlink) | Self-hosted URL shortener | ![Version](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/m11s-io/helm-charts/main/charts/shlink/Chart.yaml&label=&query=version&prefix=v) |
| [whoami](./charts/whoami) | [![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/m11s)](https://artifacthub.io/packages/helm/m11s/whoami) | Tiny HTTP server that prints OS info and HTTP request details | ![Version](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/m11s-io/helm-charts/main/charts/whoami/Chart.yaml&label=&query=version&prefix=v) |

## Quick Start

### Prerequisites

- Kubernetes 1.24+
- Helm 3.8+

### Installing Charts

```bash
# Add the Helm repository
helm repo add m11s https://m11s-io.github.io/helm-charts
helm repo update

# Install a chart
helm install my-release m11s/<chart-name>
```

## Image versions

Each chart uses `Chart.yaml`’s `appVersion` as the default primary image tag.
Leave `image.tag` empty to follow it, or set an explicit tag (optionally with
`@sha256:…`) to override it. OVMS uses `runtime.image.tag` for the same purpose.
Timestral defaults to the CPU variant and also supports `image.digest`.
Sidecars have independent explicit tags.

Renovate updates annotated `appVersion` fields and explicit sidecar image tags;
it leaves empty overrides untouched. Run `python3 scripts/check-image-defaults.py`
with Helm and the helm-unittest plugin installed to check this convention across
all charts.

## Publishing

Charts are maintained in the private monorepo and published here via CI.
