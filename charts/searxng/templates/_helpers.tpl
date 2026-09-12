{{/* searxng.name returns the chart name, truncated to 63 chars */}}
{{- define "searxng.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* searxng.fullname returns the fully qualified app name */}}
{{- define "searxng.fullname" -}}
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

{{/* searxng.chart returns the chart name and version for the helm.sh/chart label */}}
{{- define "searxng.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* searxng.labels returns the common labels for all resources */}}
{{- define "searxng.labels" -}}
helm.sh/chart: {{ include "searxng.chart" . }}
{{ include "searxng.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/* searxng.selectorLabels returns the selector labels used by Deployment and Service */}}
{{- define "searxng.selectorLabels" -}}
app.kubernetes.io/name: {{ include "searxng.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/* searxng.serviceAccountName returns the name of the ServiceAccount to use */}}
{{- define "searxng.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "searxng.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end }}

{{/* searxng.image returns the fully qualified image reference */}}
{{- define "searxng.image" -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion }}
{{- printf "%s:%s" .Values.image.repository $tag }}
{{- end }}

{{/*
searxng.valkeyServiceName returns the Service name of the bundled Valkey subchart.
It mirrors the subchart's own fullname template so the two stay in sync.
*/}}
{{- define "searxng.valkeyServiceName" -}}
{{- $valkey := .Values.valkey | default dict }}
{{- if $valkey.fullnameOverride }}
{{- $valkey.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default "valkey" $valkey.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
searxng.valkeyUrl returns the Valkey connection URL for the bundled subchart,
or an empty string when Valkey is external or unset.
*/}}
{{- define "searxng.valkeyUrl" -}}
{{- if .Values.valkey.enabled }}
{{- $port := 6379 }}
{{- if and .Values.valkey.service .Values.valkey.service.port }}
{{- $port = .Values.valkey.service.port }}
{{- end }}
{{- printf "valkey://%s:%v/0" (include "searxng.valkeyServiceName" .) $port }}
{{- else }}
{{- .Values.valkey.url }}
{{- end }}
{{- end }}

{{/*
searxng.validateValkey fails the render when the limiter is enabled without a
Valkey database, which SearXNG's bot detection requires.
*/}}
{{- define "searxng.validateValkey" -}}
{{- if .Values.limiter.enabled }}
{{- if not (or .Values.valkey.enabled .Values.valkey.url .Values.valkey.existingSecret.name) }}
{{- fail "limiter.enabled requires a Valkey database: set valkey.enabled=true to deploy the bundled subchart, or point valkey.url / valkey.existingSecret.name at an external instance" }}
{{- end }}
{{- end }}
{{- end }}
