# m11s Helm Charts

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/m11s)](https://artifacthub.io/packages/search?org=m11s)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Release Charts](https://github.com/m11s-io/helm-charts/actions/workflows/release.yml/badge.svg)](https://github.com/m11s-io/helm-charts/actions/workflows/release.yml)

A collection of production-ready Helm charts for m11s platform services, published on [Artifact Hub](https://artifacthub.io/packages/search?org=m11s).

## Available Charts

| Chart | Description | Version |
|-------|-------------|---------|
| [decap-cms](./charts/decap-cms) | Multi-tenant Decap CMS served by hostname | ![Version](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/m11s-io/helm-charts/main/charts/decap-cms/Chart.yaml&label=&query=version&prefix=v) |
| [fider](./charts/fider) | Self-hosted user feedback platform | ![Version](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/m11s-io/helm-charts/main/charts/fider/Chart.yaml&label=&query=version&prefix=v) |
| [shlink](./charts/shlink) | Self-hosted URL shortener | ![Version](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/m11s-io/helm-charts/main/charts/shlink/Chart.yaml&label=&query=version&prefix=v) |
| [whoami](./charts/whoami) | Tiny HTTP server that prints OS info and HTTP request details | ![Version](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/m11s-io/helm-charts/main/charts/whoami/Chart.yaml&label=&query=version&prefix=v) |

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

## Publishing

Charts are maintained in the private monorepo and published here via CI.
