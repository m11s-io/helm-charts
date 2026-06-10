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

## Multi-tenant setup

Set `hostMode: multi` and `hostDomain` to your base domain. Tenants on custom domains are automatically detected when the request hostname doesn't match `hostDomain`.

```yaml
fider:
  hostMode: multi
  hostDomain: example.com
  existingSecret:
    name: fider-credentials
    jwtSecretKey: jwt-secret

db:
  existingSecret:
    name: fider-db-credentials
    urlKey: database-url
```

## Source

- Chart: [github.com/m11s-io/charts](https://github.com/m11s-io/charts)
- Upstream: [github.com/getfider/fider](https://github.com/getfider/fider)
