# Fider Helm Chart

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
| `fider.existingSecret.jwtSecretKey` | Key in secret for JWT secret | `JWT_SECRET` |
| `db.existingSecret.name` | Secret containing database URL | `""` |
| `db.existingSecret.urlKey` | Key in secret for database URL | `DATABASE_URL` |
| `db.maxIdleConns` | Max idle DB connections | `2` |
| `db.maxOpenConns` | Max open DB connections | `10` |
| `blobStorage.type` | Blob storage backend: `sql` or `s3` | `sql` |
| `email.noreply` | From address for outgoing email | `""` |
| `email.smtp.enabled` | Enable SMTP | `false` |
| `email.smtp.host` | SMTP host | `""` |
| `email.smtp.port` | SMTP port | `587` |

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

## Source

- Chart: [github.com/m11s-io/charts](https://github.com/m11s-io/charts)
- Upstream: [github.com/getfider/fider](https://github.com/getfider/fider)
