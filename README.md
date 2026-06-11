# m11s Helm Charts

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/m11s)](https://artifacthub.io/packages/search?org=m11s)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Release Charts](https://github.com/m11s-io/helm-charts/actions/workflows/release.yml/badge.svg)](https://github.com/m11s-io/helm-charts/actions/workflows/release.yml)

Helm charts for m11s platform services, published on [ArtifactHub](https://artifacthub.io/packages/search?org=m11s).

## Usage

```bash
helm repo add m11s https://m11s-io.github.io/helm-charts
helm repo update
```

## Charts

| Chart | Description |
|-------|-------------|
| [fider](./charts/fider) | Self-hosted user feedback platform |

## Publishing

Charts are maintained in the private monorepo and published here via CI.
