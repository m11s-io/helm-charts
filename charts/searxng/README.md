# SearXNG Helm Chart

[![Docker Pulls](https://img.shields.io/docker/pulls/searxng/searxng.svg)](https://hub.docker.com/r/searxng/searxng/)
[![CI](https://img.shields.io/github/checks-status/searxng/searxng/master?label=CI)](https://github.com/searxng/searxng/actions)

[SearXNG](https://searxng.org) is a privacy-respecting metasearch engine. It aggregates results from
other search engines while storing no user data and serving no ads.

## Installation

```bash
helm repo add m11s https://m11s-io.github.io/helm-charts
helm repo update
helm install searxng m11s/searxng -n searxng --create-namespace -f values.yaml
```

SearXNG requires a secret key. Create it before installing:

```bash
kubectl create secret generic searxng-secret -n searxng \
  --from-literal=secret-key="$(openssl rand -hex 32)"
```

Minimal working values:

```yaml
searxng:
  baseURL: https://search.example.com
  existingSecret:
    name: searxng-secret
```

## Configuration

| Parameter | Description | Default |
|---|---|---|
| `searxng.baseURL` | Public URL of this instance (required) | `""` |
| `searxng.instanceName` | Instance name shown in the web UI | `SearXNG` |
| `searxng.imageProxy` | Proxy image results instead of hotlinking them | `true` |
| `searxng.publicInstance` | Enable hardening for publicly reachable instances | `false` |
| `searxng.method` | HTTP method for search submission: `GET` or `POST` | `GET` |
| `searxng.debug` | Enable debug mode (never on a public instance) | `false` |
| `searxng.formats` | Response formats served: `html`, `csv`, `json`, `rss` | `[html]` |
| `searxng.existingSecret.name` | Secret containing the instance secret key (required) | `""` |
| `searxng.existingSecret.secretKeyKey` | Key in the secret holding `SEARXNG_SECRET` | `secret-key` |
| `searxng.settings` | Free-form `settings.yml` fragment merged over chart defaults | `{}` |
| `limiter.enabled` | Enable the bot-detection rate limiter (requires Valkey) | `false` |
| `limiter.trustedProxies` | CIDRs whose `X-Forwarded-For` is trusted | `[127.0.0.0/8, ::1]` |
| `limiter.ipv4Prefix` | Leading bits compared when grouping IPv4 clients | `32` |
| `limiter.ipv6Prefix` | Leading bits compared when grouping IPv6 clients | `48` |
| `limiter.linkToken` | Enable the `link_token` bot-detection method | `false` |
| `limiter.passIP` | CIDRs granted unrestricted access | `[]` |
| `limiter.blockIP` | CIDRs denied access outright | `[]` |
| `limiter.extraConfig` | Raw TOML appended to `limiter.toml` | `""` |
| `valkey.enabled` | Deploy the bundled Valkey subchart | `false` |
| `valkey.url` | External Valkey URL, used when `valkey.enabled` is false | `""` |
| `valkey.existingSecret.name` | Secret containing an external Valkey URL | `""` |
| `persistence.enabled` | Mount a PVC at `/var/cache/searxng` for the favicon cache | `false` |
| `persistence.size` | Requested volume size | `1Gi` |
| `httpRoute.enabled` | Create a Gateway API HTTPRoute | `false` |
| `httpRoute.parentRefs` | Gateways the HTTPRoute attaches to; required when enabled | `[]` |
| `httpRoute.hostnames` | Hostnames the HTTPRoute matches | `[]` |
| `networkPolicy.enabled` | Protect bundled Valkey with a NetworkPolicy | `true` |
| `networkPolicy.extraIngress` | Additional raw NetworkPolicy ingress rules for bundled Valkey | `[]` |
| `resources.requests.cpu` | Default CPU request | `100m` |
| `resources.requests.memory` | Default memory request | `256Mi` |
| `resources.limits.memory` | Default memory limit | `1Gi` |

## Settings

The chart renders `/etc/searxng/settings.yml` from a small set of typed values on top of
`use_default_settings: true`, so you inherit upstream's defaults and engine list. Anything not
exposed as a typed value goes under `searxng.settings`, which is deep-merged over the chart's
defaults:

```yaml
searxng:
  baseURL: https://search.example.com
  existingSecret:
    name: searxng-secret
  settings:
    search:
      safe_search: 1
      autocomplete: duckduckgo
    ui:
      default_theme: simple
    engines:
      - name: wikipedia
        disabled: false
```

`searxng.settings` wins over the typed values, so `searxng.settings.general.instance_name`
overrides `searxng.instanceName`. See the [settings reference](https://docs.searxng.org/admin/settings/)
for every available key.

`SEARXNG_BASE_URL`, `SEARXNG_SECRET`, and `SEARXNG_VALKEY_URL` are injected as environment
variables rather than written into the ConfigMap, keeping credentials out of it.

## Rate limiting

The limiter is SearXNG's bot-detection layer. It is **disabled by default** and requires a Valkey
database — upstream's `searx/limiter.py` and `searx/botdetection/*` are the only code paths that
use Valkey, so there is no reason to run one without it.

Enable both together:

```yaml
limiter:
  enabled: true
valkey:
  enabled: true
```

The chart fails the render with an explicit message if `limiter.enabled` is set without a bundled
or external Valkey.

### Trusted proxies

> [!IMPORTANT]
> Behind a gateway or ingress, set `limiter.trustedProxies` to the CIDR the proxy's traffic
> actually arrives from.

Without it every request appears to originate from the proxy, so the limiter treats all traffic as
one client and throttles everyone at once.

Which CIDR that is depends on where the proxy runs:

| Proxy | Source the backend sees | Set `trustedProxies` to |
|---|---|---|
| Pod-based (NGINX Ingress, Traefik, Envoy Gateway) | the proxy pod's IP | the cluster **pod** CIDR |
| Host-networked (Cilium Gateway API, `hostNetwork` proxies) | the node's IP | the **node** network CIDR |

Cilium implements Gateway API through its own Envoy, which runs in the host network namespace, so
the backend sees a node address even when `gatewayAPI.hostNetwork.enabled` is `false` — that flag
controls how the listener is exposed, not where the proxy runs.

```yaml
limiter:
  enabled: true
  trustedProxies:
    - 10.10.0.0/16   # node network, for a host-networked proxy such as Cilium Gateway
```

Verify rather than assume — the failure mode is silent until traffic ramps up. After deploying,
confirm which address arrives:

```bash
kubectl logs -n searxng deploy/searxng | grep -i "limiter\|botdetection"
```

If the limiter is throttling all users together, `trustedProxies` does not cover the real source.

### External Valkey

To use a Valkey you already run, leave `valkey.enabled` at `false` and point the chart at it:

```yaml
limiter:
  enabled: true
valkey:
  url: valkey://valkey.data.svc.cluster.local:6379/0
```

For a URL containing credentials, supply it through a Secret instead:

```yaml
valkey:
  existingSecret:
    name: valkey-credentials
    urlKey: valkey-url
```

## Bundled Valkey

`valkey.enabled: true` pulls in the [official valkey-io chart](https://github.com/valkey-io/valkey-helm)
as a subchart. Configure it under the `valkey` key as usual:

```yaml
valkey:
  enabled: true
  persistence:
    enabled: true
    size: 1Gi
  resources:
    requests:
      cpu: 50m
      memory: 64Mi
```

## Routing

The chart creates only an HTTPRoute. It does not create a Gateway, because Gateways are usually
owned by the cluster/platform layer. If the Gateway is in another namespace, its listener must
allow routes from the SearXNG namespace with Gateway API `allowedRoutes`.

```yaml
httpRoute:
  enabled: true
  parentRefs:
    - name: internal-gw
      namespace: gateway
      sectionName: https
      port: 443
  hostnames:
    - search.example.com
```

## Persistence

SearXNG writes a favicon cache to `/var/cache/searxng`. The chart mounts an `emptyDir` there by
default, which is fine — the cache rebuilds itself. Enable `persistence` to keep it across restarts.

## NetworkPolicy

When bundled Valkey is enabled, the chart protects it by default: only SearXNG and Valkey
replication peers may connect on TCP 6379. `networkPolicy.extraIngress` accepts additional raw
`NetworkPolicyIngressRule` entries, for example a metrics scraper. Gateway, DNS, and upstream
search-engine traffic is platform-specific and belongs in the deployment's platform policy.

## Source

- Chart: [github.com/m11s-io/helm-charts](https://github.com/m11s-io/helm-charts)
- Upstream: [github.com/searxng/searxng](https://github.com/searxng/searxng)
