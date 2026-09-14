# shlink

[![Docker Pulls](https://img.shields.io/docker/pulls/shlinkio/shlink.svg)](https://hub.docker.com/r/shlinkio/shlink/)
[![CI](https://img.shields.io/github/checks-status/shlinkio/shlink/develop?label=CI)](https://github.com/shlinkio/shlink/actions)

Helm chart for [Shlink](https://shlink.io) — a self-hosted URL shortener.

## Usage

```bash
helm upgrade --install shlink m11s/shlink \
  --set shlink.defaultDomain=s.example.com \
  --set geolite.existingSecret.name=shlink-geolite
```

## Configuration

### Required

| Key | Description |
|-----|-------------|
| `shlink.defaultDomain` | The short domain served by this instance (e.g. `s.example.com`) |

### Database

Shlink supports two mutually exclusive backends — pick one:

**Option A — SQLite (default, no external DB required)**

SQLite stores data in `/etc/shlink/data` inside the container. Enable persistence
so the database survives pod restarts:

```yaml
persistence:
  enabled: true
  size: 1Gi
  storageClass: longhorn
```

The PVC is annotated `helm.sh/resource-policy: keep` so it survives `helm uninstall`.

**Option B — External database (recommended for production)**

Set `db.driver` to `postgres`, `mysql`, or `mssql` and point at your database server.
No PVC is needed when using an external database.

```yaml
db:
  driver: postgres
  host: postgres.dbs.svc
  name: shlink
  user: shlink
  existingSecret:
    name: shlink-db      # must contain key db-password
```

### GeoLite

GeoLite is used for visitor geolocation. Supply a license key or skip the download:

```yaml
geolite:
  existingSecret:
    name: shlink-geolite    # must contain key geolite-license-key

# OR skip geolocation entirely:
geolite:
  skipDownload: true
```

### Initial API key

```yaml
initialApiKey:
  existingSecret:
    name: shlink-api-key    # must contain key initial-api-key
```

### Redis

```yaml
redis:
  enabled: true
  servers: redis://redis.cache.svc:6379
  existingSecret:
    name: shlink-redis      # must contain keys redis-user, redis-password
```

### HTTPRoute (Gateway API)

```yaml
httpRoute:
  enabled: true
  parentRefs:
    - name: public-gateway
      namespace: gateway
  hostnames:
    - s.example.com
```
