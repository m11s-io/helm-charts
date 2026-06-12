# decap-cms

Helm chart for running the m11s multi-tenant Decap CMS image.

The chart stores tenant configuration in `tenants.json`, mounts it into the pod, and the image generates one `/admin/config.yml` per hostname at startup.

## Example

```yaml
tenants:
  - hostname: cms.example.com
    gitlabRepo: example/products/site
    gitlabBranch: decap
    gitlabAppId: xxx
    uploadUrl: https://proxy.example.com/upload
  - hostname: cms-blog.example.com
    gitlabRepo: example/products/blog
    gitlabBranch: main
    gitlabAppId: yyy
    uploadUrl: https://proxy-blog.example.com/upload

httpRoute:
  enabled: true
  parentRefs:
    - name: public
      namespace: gateway
```

When `httpRoute.hostnames` is omitted, it defaults to `tenants[*].hostname`.

## Existing ConfigMap

```yaml
existingTenantsConfigMap: decap-cms-tenants
```

The ConfigMap must contain a `tenants.json` key.

## Existing PVC

```yaml
existingTenantsPersistentVolumeClaim: decap-cms-tenants
```

The PVC must contain a `tenants.json` file at its root.
