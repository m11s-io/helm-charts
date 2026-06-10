# whoami Helm Chart

[whoami](https://github.com/traefik/whoami) is a tiny HTTP server that prints OS information and HTTP request details. Useful for testing ingress, routing, and load balancing.

## Installation

```bash
helm repo add m11s https://m11s-io.github.io/charts
helm repo update
helm install whoami m11s/whoami -n whoami --create-namespace
```

## Configuration

| Parameter | Description | Default |
|---|---|---|
| `whoami.port` | Port whoami listens on inside the container | `80` |
| `whoami.name` | Display name printed in responses (useful with multiple replicas) | `""` |
| `whoami.verbose` | Enable verbose request logging | `false` |
| `replicaCount` | Number of pod replicas | `1` |
| `service.type` | Kubernetes Service type | `ClusterIP` |
| `service.port` | Port the Service listens on | `80` |
| `httpRoute.enabled` | Enable a Gateway API HTTPRoute | `false` |
| `httpRoute.parentRefs` | Gateways the HTTPRoute attaches to; required when enabled | `[]` |
| `httpRoute.hostnames` | Hostnames the HTTPRoute matches | `[]` |
| `resources.requests.cpu` | Default CPU request | `10m` |
| `resources.requests.memory` | Default memory request | `16Mi` |
| `resources.limits.memory` | Default memory limit | `64Mi` |

## Endpoints

| Path | Description |
|---|---|
| `/` | Prints hostname, IPs, and full HTTP request |
| `/api` | Same as `/` but as JSON |
| `/health` | Health check; returns 200 by default, accepts POST to change the status code |
| `/data` | Returns a configurable payload size (`?size=1&unit=MB`) |
| `/bench` | Minimal response for benchmarking |
| `/echo` | WebSocket echo |

## Examples

### Basic install

```bash
helm install whoami m11s/whoami -n whoami --create-namespace
```

### Multiple named replicas with HTTPRoute

```yaml
replicaCount: 3

whoami:
  name: my-app

httpRoute:
  enabled: true
  parentRefs:
    - name: gateway
      namespace: gateway
  hostnames:
    - whoami.example.com
```

The chart creates only an HTTPRoute. It does not create a Gateway, because Gateways are usually owned by the cluster/platform layer. If the Gateway is in another namespace, its listener must allow routes from the whoami namespace with Gateway API `allowedRoutes`.

### Manipulate the health check for testing

```bash
# Make /health return 503
kubectl run -it --rm --restart=Never curl --image=curlimages/curl -- \
  curl -X POST -d '503' http://whoami.<namespace>/health
```

## Source

- Chart: [github.com/m11s-io/charts](https://github.com/m11s-io/charts)
- Upstream: [github.com/traefik/whoami](https://github.com/traefik/whoami)
