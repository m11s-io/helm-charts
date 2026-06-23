# shlink

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

By default Shlink uses SQLite stored in `/etc/shlink/data`. Enable `persistence.enabled=true` to persist SQLite across pod restarts, or switch to an external database:

```yaml
db:
  driver: postgres      # postgres, mysql, mssql
  host: postgres.dbs.svc
  name: shlink
  user: shlink
  existingSecret:
    name: shlink-db     # must contain key db-password
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

### Persistence (SQLite)

```yaml
persistence:
  enabled: true
  size: 1Gi
  storageClass: longhorn
```

The PVC is annotated with `helm.sh/resource-policy: keep` so it survives `helm uninstall`.
