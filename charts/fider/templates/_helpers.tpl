{{/* fider.name returns the chart name, truncated to 63 chars */}}
{{- define "fider.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* fider.fullname returns the fully qualified app name */}}
{{- define "fider.fullname" -}}
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

{{/* fider.chart returns the chart name and version for helm.sh/chart label */}}
{{- define "fider.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* fider.labels returns the common labels for all resources */}}
{{- define "fider.labels" -}}
helm.sh/chart: {{ include "fider.chart" . }}
{{ include "fider.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/* fider.selectorLabels returns the selector labels used by Deployment and Service */}}
{{- define "fider.selectorLabels" -}}
app.kubernetes.io/name: {{ include "fider.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/* fider.serviceAccountName returns the name of the ServiceAccount to use */}}
{{- define "fider.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "fider.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end }}

{{/* fider.image returns the fully qualified image reference */}}
{{- define "fider.image" -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion }}
{{- printf "%s:%s" .Values.image.repository $tag }}
{{- end }}
