{{/* shlink.name returns the chart name, truncated to 63 chars */}}
{{- define "shlink.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* shlink.fullname returns the fully qualified app name */}}
{{- define "shlink.fullname" -}}
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

{{/* shlink.chart returns the chart name and version for helm.sh/chart label */}}
{{- define "shlink.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* shlink.labels returns the common labels for all resources */}}
{{- define "shlink.labels" -}}
helm.sh/chart: {{ include "shlink.chart" . }}
{{ include "shlink.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/* shlink.selectorLabels returns the selector labels used by Deployment and Service */}}
{{- define "shlink.selectorLabels" -}}
app.kubernetes.io/name: {{ include "shlink.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/* shlink.serviceAccountName returns the name of the ServiceAccount to use */}}
{{- define "shlink.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "shlink.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end }}

{{/* shlink.image returns the fully qualified image reference */}}
{{- define "shlink.image" -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion }}
{{- printf "%s:%s" .Values.image.repository $tag }}
{{- end }}
