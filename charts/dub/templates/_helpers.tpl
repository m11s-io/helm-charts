{{/* dub.name returns the chart name, truncated to 63 chars */}}
{{- define "dub.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* dub.fullname returns the fully qualified app name */}}
{{- define "dub.fullname" -}}
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

{{/* dub.chart returns the chart name and version for helm.sh/chart label */}}
{{- define "dub.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* dub.labels returns the common labels for all resources */}}
{{- define "dub.labels" -}}
helm.sh/chart: {{ include "dub.chart" . }}
{{ include "dub.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/* dub.selectorLabels returns the selector labels used by Deployment and Service */}}
{{- define "dub.selectorLabels" -}}
app.kubernetes.io/name: {{ include "dub.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/* dub.serviceAccountName returns the name of the ServiceAccount to use */}}
{{- define "dub.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "dub.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end }}

{{/* dub.image returns the fully qualified image reference */}}
{{- define "dub.image" -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion }}
{{- printf "%s:%s" .Values.image.repository $tag }}
{{- end }}
