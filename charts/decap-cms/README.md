# decap-cms

Helm chart for running the m11s multi-tenant Decap CMS image.

The chart stores tenant configuration in `tenants.json`, mounts it into the pod, and the image generates one `/admin/config.yml` per hostname at startup.

## Example

```yaml
tenants:
  - slug: example
    gitlabRepo: example/products/site
    gitlabBranch: main
    gitlabAppId: xxx
    uploadUrl: https://proxy.example.com/upload
    postsFolder: website/src/content/posts
  - slug: blog
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

`postsFolder` is relative to the Git repository root and defaults to `posts`.

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
