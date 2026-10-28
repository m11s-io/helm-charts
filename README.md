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
`@sha256:…`) to override it. All charts also support `image.digest`; when set, the digest takes precedence
over tag. Timestral defaults to the CPU variant. Sidecars have independent image
versions.

Renovate updates annotated `appVersion` fields and explicit sidecar image tags;
it leaves empty overrides untouched. The shared image helper is covered by the
regular Helm unit tests.

## Publishing

Charts are maintained in the private monorepo and published here via CI.

## Shared chart library and values API

All nine application charts depend on the local `charts/common` library chart
(`m11s-common`). It provides only shared naming, labels/selectors, image,
ServiceAccount, Service, HTTPRoute, and PVC templates. Application charts keep
workloads, environment, probes, host derivation, component selectors, and
application-specific security settings local.

Service and HTTPRoute renderers take a `root` chart context and derive the usual
name, selectors, and service/route settings from it. Callers supply only actual
exceptions such as sidecar ports, component selectors, or derived hostnames.
The image helper takes the chart context directly. One pod-label helper accepts
an optional component and protects fixed identity labels from custom overrides.
Resource label maps are merged before rendering, with chart identity and fixed
component labels taking precedence over custom labels.

Common application values are `image`, `resources`, `securityContext`,
`imagePullSecrets`, `podLabels`, `podAnnotations`, and `serviceAccount`. Service
Accounts are created by default in all charts and token automount is disabled
unless `serviceAccount.automountServiceAccountToken: true` is set. The default
pod labels are merged without allowing user labels to replace selector labels.

| Old key | New key |
|---|---|
| OVMS `runtime.image.*` | `image.*` |
| OVMS `runtime.resources` / `runtime.securityContext` | `resources` / `securityContext` |
| Timestral `runtime.resources` / `runtime.securityContext` | `resources` / `securityContext` |
| `persistence.storageClass` (OVMS, Timestral, SearXNG) | `persistence.storageClassName` |
| Shlink `data.storageClass` | `data.storageClassName` |
| PVC `accessMode` | `accessModes` (a list, e.g. `[ReadWriteOnce]`) |

There are no deprecated aliases for the old keys. For `storageClassName`, `null`
uses the cluster default StorageClass, `""` explicitly requests no dynamic
provisioner, and a class name selects that StorageClass. PVCs retain their
existing names and defaults; set `existingClaim` where offered to reuse a claim.

## Build, test, and release

Build dependencies before rendering or linting application charts:

```bash
helm repo add valkey https://valkey.io/valkey-helm/
for chart in charts/*; do
  grep -q '^type: library$' "$chart/Chart.yaml" && continue
  helm dependency build --skip-refresh "$chart"
done
# Requires the helm-unittest plugin.
helm unittest charts/*
helm lint charts/whoami --strict
```

`Chart.lock` files are committed. Do not commit generated dependency archives.
The `file://../common` dependency is bundled inside each packaged application
chart, so installed charts do not need access to this source repository. When
the library version changes, update the dependency pin in every application
chart and rebuild all locks before packaging. The release workflow performs this
build before chart-releaser runs. Root-anchored `/*.tgz` entries in `.helmignore`
keep local dependency archives in the packaged chart.
