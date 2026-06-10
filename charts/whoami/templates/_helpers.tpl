{{/* whoami.name returns the chart name, truncated to 63 chars */}}
{{- define "whoami.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* whoami.fullname returns the fully qualified app name */}}
{{- define "whoami.fullname" -}}
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

{{/* whoami.chart returns the chart name and version for helm.sh/chart label */}}
{{- define "whoami.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* whoami.labels returns the common labels for all resources */}}
{{- define "whoami.labels" -}}
helm.sh/chart: {{ include "whoami.chart" . }}
{{ include "whoami.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/* whoami.selectorLabels returns the selector labels used by Deployment and Service */}}
{{- define "whoami.selectorLabels" -}}
app.kubernetes.io/name: {{ include "whoami.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/* whoami.serviceAccountName returns the name of the ServiceAccount to use */}}
{{- define "whoami.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "whoami.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end }}

{{/* whoami.image returns the fully qualified image reference */}}
{{- define "whoami.image" -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion }}
{{- printf "%s:%s" .Values.image.repository $tag }}
{{- end }}
