# Maintaining charts

## Image versions

Each chart uses `Chart.yaml`’s `appVersion` as the default primary image tag.
Leave `image.tag` empty to follow it, or set an explicit tag (optionally with
`@sha256:…`) to override it. All charts also support `image.digest`; when set, the digest takes precedence
over tag. Sidecars have independent image
versions.

Renovate updates annotated `appVersion` fields and explicit sidecar image tags;
it leaves empty overrides untouched. The shared image helper is covered by the
regular Helm unit tests.

## Shared chart library and values API

All application charts depend on the local `charts/common` library chart
(`m11s-common`). It provides only shared naming, labels/selectors, image,
ServiceAccount, Service, HTTPRoute, and PVC templates. Application charts keep
workloads, environment, probes, host derivation, component selectors, and
application-specific security settings local.

Service and HTTPRoute renderers take a `root` chart context and derive the usual
name, selectors, and service/route settings from it. Callers supply only actual
exceptions such as sidecar ports, component selectors, or derived hostnames.
The image helper takes the chart context directly. One pod-label helper accepts
an optional component and protects fixed identity labels from custom overrides.
Resource label maps are merged before rendering, with chart identity and fixed
component labels taking precedence over custom labels.

Common application values are `image`, `resources`, `securityContext`,
`imagePullSecrets`, `podLabels`, `podAnnotations`, and `serviceAccount`. Service
Accounts are created by default in all charts and token automount is disabled
unless `serviceAccount.automountServiceAccountToken: true` is set. The default
pod labels are merged without allowing user labels to replace selector labels.

| Old key | New key |
|---|---|
| OVMS `runtime.image.*` | `image.*` |
| OVMS `runtime.resources` / `runtime.securityContext` | `resources` / `securityContext` |
| `persistence.storageClass` (OVMS, SearXNG) | `persistence.storageClassName` |
| Shlink `data.storageClass` | `data.storageClassName` |
| PVC `accessMode` | `accessModes` (a list, e.g. `[ReadWriteOnce]`) |

There are no deprecated aliases for the old keys. For `storageClassName`, `null`
uses the cluster default StorageClass, `""` explicitly requests no dynamic
provisioner, and a class name selects that StorageClass. PVCs retain their
existing names and defaults; set `existingClaim` where offered to reuse a claim.

## Build, test, and release

Build dependencies before rendering or linting application charts:

```bash
helm repo add valkey https://valkey.io/valkey-helm/
for chart in charts/*; do
  grep -q '^type: library$' "$chart/Chart.yaml" && continue
  helm dependency build --skip-refresh "$chart"
done
# Requires the helm-unittest plugin.
helm unittest charts/*
helm lint charts/whoami --strict
```

`Chart.lock` files are committed. Do not commit generated dependency archives.
The `file://../common` dependency is bundled inside each packaged application
chart, so installed charts do not need access to this source repository. When
the library version changes, update the dependency pin in every application
chart and rebuild all locks before packaging. The release workflow performs this
build before chart-releaser runs. Root-anchored `/*.tgz` entries in `.helmignore`
keep local dependency archives in the packaged chart.
