{{/* decap-cms.name returns the chart name, truncated to 63 chars */}}
{{- define "decap-cms.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* decap-cms.fullname returns the fully qualified app name */}}
{{- define "decap-cms.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/* decap-cms.chart returns the chart name and version for helm.sh/chart label */}}
{{- define "decap-cms.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* decap-cms.labels returns the common labels for all resources */}}
{{- define "decap-cms.labels" -}}
helm.sh/chart: {{ include "decap-cms.chart" . }}
{{ include "decap-cms.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/* decap-cms.selectorLabels returns the selector labels used by Deployment and Service */}}
{{- define "decap-cms.selectorLabels" -}}
app.kubernetes.io/name: {{ include "decap-cms.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/* decap-cms.serviceAccountName returns the name of the ServiceAccount to use */}}
{{- define "decap-cms.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "decap-cms.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end }}

{{/* decap-cms.image returns the fully qualified image reference */}}
{{- define "decap-cms.image" -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion }}
{{- printf "%s:%s" .Values.image.repository $tag }}
{{- end }}

{{/* decap-cms.tenantsConfigMapName returns the ConfigMap name containing tenants.json */}}
{{- define "decap-cms.tenantsConfigMapName" -}}
{{- default (include "decap-cms.fullname" .) .Values.existingTenantsConfigMap }}
{{- end }}

{{/* decap-cms.validateTenantsSource validates tenant config source settings */}}
{{- define "decap-cms.validateTenantsSource" -}}
{{- if and .Values.existingTenantsConfigMap .Values.existingTenantsPersistentVolumeClaim }}
{{- fail "only one of existingTenantsConfigMap or existingTenantsPersistentVolumeClaim can be set" }}
{{- end }}
{{- end }}

{{/* decap-cms.httpRouteHostnames returns HTTPRoute hostnames */}}
{{- define "decap-cms.httpRouteHostnames" -}}
{{- toYaml .Values.httpRoute.hostnames }}
{{- end }}
