{{- define "ovms.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- define "ovms.fullname" -}}
{{- if .Values.fullnameOverride }}{{ .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}{{ else }}{{ $name := include "ovms.name" . }}{{ if contains $name .Release.Name }}{{ .Release.Name | trunc 63 | trimSuffix "-" }}{{ else }}{{ printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}{{ end }}{{ end }}
{{- end -}}
{{- define "ovms.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
{{ include "ovms.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
{{- define "ovms.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ovms.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
{{- define "ovms.claimName" -}}
{{- .Values.persistence.existingClaim | default (.Values.persistence.nameOverride | default (printf "%s-model-cache" (include "ovms.fullname" .))) -}}
{{- end -}}
