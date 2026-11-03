# m11s Helm Charts

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/m11s)](https://artifacthub.io/packages/search?org=m11s)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
| Chart | Description | Version |
|-------|-------------|---------|
| [comfyui](charts/comfyui/README.md) | ComfyUI for NVIDIA and AMD GPUs | [![Version](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/m11s-io/helm-charts/main/charts/comfyui/Chart.yaml&label=&query=version&prefix=v)](https://artifacthub.io/packages/helm/m11s/comfyui) |
| [decap&#8209;cms](charts/decap-cms/README.md) | Decap CMS with S3 media uploads | [![Version](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/m11s-io/helm-charts/main/charts/decap-cms/Chart.yaml&label=&query=version&prefix=v)](https://artifacthub.io/packages/helm/m11s/decap-cms) |
| [dub](charts/dub/README.md) | Link management platform | [![Version](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/m11s-io/helm-charts/main/charts/dub/Chart.yaml&label=&query=version&prefix=v)](https://artifacthub.io/packages/helm/m11s/dub) |
| [fider](charts/fider/README.md) | User feedback and feature voting | [![Version](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/m11s-io/helm-charts/main/charts/fider/Chart.yaml&label=&query=version&prefix=v)](https://artifacthub.io/packages/helm/m11s/fider) |
| [ovms](charts/ovms/README.md) | OpenVINO inference server | [![Version](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/m11s-io/helm-charts/main/charts/ovms/Chart.yaml&label=&query=version&prefix=v)](https://artifacthub.io/packages/helm/m11s/ovms) |
| [searxng](charts/searxng/README.md) | Privacy-focused metasearch engine | [![Version](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/m11s-io/helm-charts/main/charts/searxng/Chart.yaml&label=&query=version&prefix=v)](https://artifacthub.io/packages/helm/m11s/searxng) |
| [shlink](charts/shlink/README.md) | URL shortener | [![Version](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/m11s-io/helm-charts/main/charts/shlink/Chart.yaml&label=&query=version&prefix=v)](https://artifacthub.io/packages/helm/m11s/shlink) |
| [whoami](charts/whoami/README.md) | HTTP request and system diagnostics | [![Version](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/m11s-io/helm-charts/main/charts/whoami/Chart.yaml&label=&query=version&prefix=v)](https://artifacthub.io/packages/helm/m11s/whoami) |

## Install

```sh
helm repo add <repository-name> <repository-url>
helm repo update
helm install <release-name> <repository-name>/<chart-name>
```
