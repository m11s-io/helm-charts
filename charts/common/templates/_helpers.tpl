{{- define "m11s-common.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "m11s-common.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}{{ .Release.Name | trunc 63 | trimSuffix "-" }}{{- else -}}{{ printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}{{- end -}}
{{- end -}}
{{- end -}}

{{- define "m11s-common.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "m11s-common.labels" -}}
helm.sh/chart: {{ include "m11s-common.chart" . }}
{{ include "m11s-common.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "m11s-common.selectorLabels" -}}
app.kubernetes.io/name: {{ include "m11s-common.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "m11s-common.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}{{ default (include "m11s-common.fullname" .) .Values.serviceAccount.name }}{{- else -}}{{ default "default" .Values.serviceAccount.name }}{{- end -}}
{{- end -}}

{{- define "m11s-common.image" -}}
{{- $image := .Values.image -}}{{- $tag := $image.tag | default .Chart.AppVersion -}}
{{- if $image.digest -}}{{ printf "%s@%s" $image.repository $image.digest }}{{- else -}}{{ printf "%s:%s" $image.repository $tag }}{{- end -}}
{{- end -}}

{{- define "m11s-common.serviceAccount" -}}
{{- $root := . -}}{{- if $root.Values.serviceAccount.create }}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "m11s-common.serviceAccountName" $root }}
  labels:
    {{- include "m11s-common.labels" $root | nindent 4 }}
  {{- with $root.Values.serviceAccount.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
automountServiceAccountToken: {{ $root.Values.serviceAccount.automountServiceAccountToken }}
{{- end -}}
{{- end -}}

{{- define "m11s-common.service" -}}
{{- $root := .root -}}
{{- $labels := merge (dict) (include "m11s-common.labels" $root | fromYaml) (.extraLabels | default dict) -}}
{{- $selector := merge (dict) (include "m11s-common.selectorLabels" $root | fromYaml) (.extraSelector | default dict) -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ .name | default (include "m11s-common.fullname" $root) }}
  labels:
    {{- toYaml $labels | nindent 4 }}
spec:
  type: {{ .type | default $root.Values.service.type }}
  ports:
    - port: {{ .port | default $root.Values.service.port }}
      targetPort: {{ .targetPort | default "http" }}
      protocol: TCP
      name: {{ .portName | default "http" }}
  selector:
    {{- toYaml $selector | nindent 4 }}
{{- end -}}

{{- define "m11s-common.httpRoute" -}}
{{- $root := .root -}}{{- $route := .route | default $root.Values.httpRoute -}}
{{- if $route.enabled -}}
{{- if not $route.parentRefs -}}{{ fail "httpRoute.parentRefs must contain at least one Gateway reference when httpRoute.enabled is true" }}{{- end -}}
{{- $name := .name | default (include "m11s-common.fullname" $root) -}}
{{- $hostnames := $route.hostnames -}}
{{- if hasKey . "hostnames" -}}{{- $hostnames = .hostnames -}}{{- end -}}
{{- $labels := merge (dict) (include "m11s-common.labels" $root | fromYaml) (.extraLabels | default dict) ($route.labels | default dict) -}}
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: {{ $name }}
  labels:
    {{- toYaml $labels | nindent 4 }}
  {{- with $route.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  parentRefs:
    {{- toYaml $route.parentRefs | nindent 4 }}
  {{- with $hostnames }}
  hostnames:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  rules:
    - matches:
        - path:
            type: {{ .pathType | default "PathPrefix" }}
            value: {{ .path | default "/" }}
      backendRefs:
        - name: {{ $name }}
          port: {{ .port | default $root.Values.service.port }}
{{- end -}}
{{- end -}}

{{- define "m11s-common.pvc" -}}
{{- $root := .root -}}{{- $p := .persistence -}}
{{- if and $p.enabled (not $p.existingClaim) }}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ .name }}
  labels:
    {{- include "m11s-common.labels" $root | nindent 4 }}
  {{- with .annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  accessModes:
    {{- toYaml $p.accessModes | nindent 4 }}
  resources:
    requests:
      storage: {{ $p.size }}
  {{- if and (hasKey $p "storageClassName") (ne $p.storageClassName nil) }}
  storageClassName: {{ $p.storageClassName | quote }}
  {{- end }}
{{- end -}}
{{- end -}}

{{- define "m11s-common.podLabels" -}}
{{- $root := .root -}}
{{- $custom := $root.Values.podLabels | default dict -}}
{{- $fixed := include "m11s-common.selectorLabels" $root | fromYaml -}}
{{- if hasKey . "component" -}}
{{- $custom = omit $custom "app.kubernetes.io/component" -}}
{{- with .component -}}{{- $_ := set $fixed "app.kubernetes.io/component" . -}}{{- end -}}
{{- end -}}
{{- toYaml (merge (dict) $fixed $custom) -}}
{{- end -}}
