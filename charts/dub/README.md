# dub Helm Chart

[![Docker Pulls](https://img.shields.io/docker/pulls/m11s/dub.svg)](https://hub.docker.com/r/m11s/dub/)
[![Build Status](https://github.com/dubinc/dub/workflows/CI/badge.svg?branch=main)](https://github.com/dubinc/dub/actions)

[Dub](https://dub.co) is an open-source link management platform — short links, analytics, and team workspaces.

## Installation

```bash
helm repo add m11s https://m11s-io.github.io/charts
helm repo update
helm install dub m11s/dub -n dub --create-namespace -f values.yaml
```

## Configuration

### Required

| Key | Description |
|-----|-------------|
| `dub.appUrl` | Public URL of this Dub instance (e.g. `https://dub.example.com`) |
| `auth.existingSecret.name` | Secret containing `NEXTAUTH_SECRET`, `ENCRYPTION_KEY`, `CRON_SECRET` |
| `db.existingSecret.name` | Secret containing `DATABASE_URL` (full MySQL connection string) |

### Redis

Dub requires a Redis-compatible store. Two options:

**Option A — Upstash REST endpoint**

```yaml
redis:
  upstash:
    restUrl: https://your-instance.upstash.io
    existingSecret:
      name: dub-redis
      tokenKey: upstash-redis-token
```

**Option B — redis-http-proxy sidecar** (wraps a standard Redis as an Upstash-compatible REST endpoint)

```yaml
redis:
  srh:
    enabled: true
    connectionString: redis://redis.cache.svc:6379
    existingSecret:
      name: dub-srh
      tokenKey: srh-token
```

### QStash (background jobs)

QStash enables webhooks, bulk imports, and cron jobs. Leave the secret unset to disable background jobs.

```yaml
qstash:
  url: https://qstash.upstash.io
  existingSecret:
    name: dub-qstash
    tokenKey: qstash-token
    currentSigningKeyKey: qstash-current-signing-key
    nextSigningKeyKey: qstash-next-signing-key
```

### Email

```yaml
# Resend (preferred)
email:
  resend:
    existingSecret:
      name: dub-email
      apiKeyKey: resend-api-key

# SMTP fallback
email:
  smtp:
    host: smtp.example.com
    port: 587
    user: dub@example.com
    existingSecret:
      name: dub-smtp
      passwordKey: smtp-password
```

### Storage (S3-compatible)

```yaml
storage:
  endpoint: https://s3.example.com
  baseUrl: https://assets.example.com
  publicBucket: dub-public
  privateBucket: dub-private
  existingSecret:
    name: dub-storage
    accessKeyIdKey: storage-access-key-id
    secretAccessKeyKey: storage-secret-access-key
```

### Tinybird (analytics)

```yaml
tinybird:
  apiUrl: https://api.tinybird.co
  existingSecret:
    name: dub-tinybird
    apiKeyKey: tinybird-api-key
```

### HTTPRoute (Gateway API)

```yaml
httpRoute:
  enabled: true
  parentRefs:
    - name: public-gateway
      namespace: gateway
  hostnames:
    - dub.example.com
```

### NetworkPolicy

NetworkPolicy is disabled by default. When enabled, it allows ingress from `networkPolicy.gatewayNamespace` and egress to the database namespace plus internet (Upstash, QStash, Tinybird, etc.).

```yaml
networkPolicy:
  enabled: true
  gatewayNamespace: gateway
  databaseNamespace: dbs
  databasePort: 3306
```

## Parameters

| Parameter | Description | Default |
|---|---|---|
| `replicaCount` | Number of pod replicas | `1` |
| `service.type` | Kubernetes Service type | `ClusterIP` |
| `service.port` | Port the Service listens on | `3000` |
| `httpRoute.enabled` | Enable a Gateway API HTTPRoute | `false` |
| `httpRoute.parentRefs` | Gateways the HTTPRoute attaches to; required when enabled | `[]` |
| `httpRoute.hostnames` | Hostnames the HTTPRoute matches | `[]` |
| `networkPolicy.enabled` | Enable a NetworkPolicy | `false` |
| `networkPolicy.databasePort` | Database port allowed for egress | `3306` |
| `networkPolicy.internetEgress.enabled` | Allow internet egress | `true` |
| `resources.requests.cpu` | CPU request | `100m` |
| `resources.requests.memory` | Memory request | `512Mi` |
| `resources.limits.memory` | Memory limit | `1Gi` |
| `env` | Extra non-sensitive environment variables | `{}` |
| `extraEnv` | Extra env var objects (name/value or name/valueFrom) | `[]` |
| `extraEnvFrom` | Extra envFrom sources (configMapRef, secretRef) | `[]` |

## Source

- Chart: [github.com/m11s-io/charts](https://github.com/m11s-io/charts)
- Upstream: [github.com/dubinc/dub](https://github.com/dubinc/dub)
