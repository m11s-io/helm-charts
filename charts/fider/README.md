# Fider Helm Chart

[![Docker Pulls](https://img.shields.io/docker/pulls/getfider/fider.svg)](https://hub.docker.com/r/getfider/fider/)
[![CI](https://img.shields.io/github/checks-status/getfider/fider/main?label=CI)](https://github.com/getfider/fider/actions)

[Fider](https://fider.io) is a self-hosted user feedback platform that helps teams collect, organize, and prioritize feedback.

## Installation

```bash
helm repo add m11s https://m11s-io.github.io/charts
helm repo update
helm install fider m11s/fider -n fider --create-namespace -f values.yaml
```

## Configuration

| Parameter | Description | Default |
|---|---|---|
| `fider.hostMode` | Host mode: `single` or `multi` | `single` |
| `fider.baseURL` | Public URL of this Fider instance (required when `hostMode=single`) | `""` |
| `fider.hostDomain` | Base domain for multi-tenant subdomain routing (required when `hostMode=multi`) | `""` |
| `fider.logLevel` | Log level | `INFO` |
| `fider.existingSecret.name` | Secret containing JWT secret | `""` |
| `fider.existingSecret.jwtSecretKey` | Key in secret for JWT secret | `jwt-secret` |
| `db.existingSecret.name` | Secret containing database URL | `""` |
| `db.existingSecret.urlKey` | Key in secret for database URL | `database-url` |
| `db.maxIdleConns` | Max idle DB connections | `2` |
| `db.maxOpenConns` | Max open DB connections | `4` |
| `blobStorage.type` | Blob storage backend: `sql`, `s3`, or `fs` | `sql` |
| `email.noreply` | From address for outgoing email | `""` |
| `email.smtp.enabled` | Enable SMTP | `false` |
| `email.smtp.host` | SMTP host | `""` |
| `email.smtp.port` | SMTP port | `587` |
| `httpRoute.enabled` | Create a Gateway API HTTPRoute | `false` |
| `httpRoute.parentRefs` | Gateways the HTTPRoute attaches to; required when enabled | `[]` |
| `httpRoute.hostnames` | Hostnames the HTTPRoute matches | `[]` |
| `networkPolicy.enabled` | Create a NetworkPolicy for Fider pods | `false` |
| `networkPolicy.gatewayNamespace` | Gateway namespace allowed to reach Fider; empty allows same-namespace pods | `""` |
| `networkPolicy.databaseNamespace` | Database namespace allowed for egress; empty allows same-namespace pods | `""` |
| `networkPolicy.databasePort` | PostgreSQL port allowed for database egress | `5432` |
| `networkPolicy.dnsEgress.enabled` | Allow DNS egress on TCP/UDP port 53 | `true` |
| `resources.requests.cpu` | Default CPU request | `100m` |
| `resources.requests.memory` | Default memory request | `128Mi` |
| `resources.limits.memory` | Default memory limit | `512Mi` |

## Host modes

Fider supports two deployment models controlled by `fider.hostMode`.

### Single-tenant (`hostMode: single`)

One Fider instance serves one feedback board at a fixed URL. This is the default.

```yaml
fider:
  hostMode: single
  baseURL: https://feedback.mycompany.com
```

The `fider.hostDomain` field is ignored in single mode.

### Multi-tenant (`hostMode: multi`)

One Fider instance hosts many independent feedback boards. Each board is identified by its hostname. `fider.hostDomain` is **required** in this mode — it tells Fider which base domain it owns.

Fider uses `hostDomain` to distinguish two tenant types:

| Tenant type | Hostname pattern | Example |
|---|---|---|
| **Subdomain tenant** | `<slug>.<hostDomain>` | `acme.feedback.example.com` |
| **Custom domain tenant** | anything else | `feedback.acme.io` |

When a request arrives, Fider checks: does the hostname end with `.hostDomain`? If yes → subdomain tenant. If no → custom domain tenant. The `baseURL` field is not required in multi mode; Fider derives the tenant from the incoming request host.

```yaml
fider:
  hostMode: multi
  hostDomain: feedback.example.com
  existingSecret:
    name: fider-credentials
    jwtSecretKey: jwt-secret

db:
  existingSecret:
    name: fider-db-credentials
    urlKey: database-url
```

#### Custom domain tenants

To route a custom domain (e.g. `feedback.acme.io`) to the right tenant, point the domain's DNS to your ingress/gateway and configure a hostname rule that forwards to the Fider service. Fider matches the `Host` header to the tenant record in its database — no extra chart config is needed beyond `hostMode: multi`.

#### Wildcard ingress for subdomain tenants

For subdomain tenants, configure a wildcard hostname (e.g. `*.feedback.example.com`) on your HTTPRoute or Ingress so all subdomain requests reach Fider.
When `fider.hostMode` is `multi` and chart-managed `httpRoute` is enabled, the chart automatically adds `login.<fider.hostDomain>` to the HTTPRoute hostnames for upstream Fider's host-wide signup/OAuth flow.

```yaml
httpRoute:
  enabled: true
  parentRefs:
    - name: gateway
      namespace: gateway
  hostnames:
    - "*.feedback.example.com"
    - "feedback.acme.io"        # custom domain tenant
    - "feedback.other-client.com"  # another custom domain tenant
```

The chart creates only an HTTPRoute. It does not create a Gateway, because Gateways are usually owned by the cluster/platform layer. If the Gateway is in another namespace, its listener must allow routes from the Fider namespace with Gateway API `allowedRoutes`.

## NetworkPolicy

NetworkPolicy is disabled by default. When enabled, the policy allows ingress from `networkPolicy.gatewayNamespace`; if that value is empty, ingress is limited to pods in the release namespace. Egress allows DNS on TCP/UDP port 53, PostgreSQL on `networkPolicy.databasePort` to the same namespace or configured database namespace, and optional internet egress for OAuth, email, webhooks, and object storage.

## Source

- Chart: [github.com/m11s-io/charts](https://github.com/m11s-io/charts)
- Upstream: [github.com/getfider/fider](https://github.com/getfider/fider)
