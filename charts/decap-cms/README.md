# decap-cms

Helm chart for running the m11s multi-tenant Decap CMS image.

The chart stores tenant configuration in `tenants.json`, mounts it into the pod, and the image generates one `/admin/config.yml` per hostname at startup.

## Example

```yaml
tenants:
  - hostname: cms.m11s.io
    gitlabRepo: m11s/products/m11s
    gitlabBranch: decap
    gitlabAppId: xxx
    uploadUrl: https://proxy.m11s.io/upload
  - hostname: cms.workanoo.io
    gitlabRepo: m11s/products/workanoo
    gitlabBranch: main
    gitlabAppId: yyy
    uploadUrl: https://proxy.workanoo.io/upload

httpRoute:
  enabled: true
  parentRefs:
    - name: public
      namespace: gateway
```

When `httpRoute.hostnames` is omitted, it defaults to `tenants[*].hostname`.
