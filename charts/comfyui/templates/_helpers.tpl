{{/* comfyui.name returns the chart name, truncated to 63 chars */}}
{{- define "comfyui.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* comfyui.fullname returns the fully qualified app name */}}
{{- define "comfyui.fullname" -}}
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

{{/* comfyui.chart returns the chart name and version for helm.sh/chart label */}}
{{- define "comfyui.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* comfyui.labels returns the common labels for all resources */}}
{{- define "comfyui.labels" -}}
helm.sh/chart: {{ include "comfyui.chart" . }}
{{ include "comfyui.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/* comfyui.selectorLabels returns the selector labels used by Deployment and Service */}}
{{- define "comfyui.selectorLabels" -}}
app.kubernetes.io/name: {{ include "comfyui.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/* comfyui.serviceAccountName returns the name of the ServiceAccount to use */}}
{{- define "comfyui.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "comfyui.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end }}

{{/* comfyui.image returns the fully qualified image reference */}}
{{- define "comfyui.image" -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion }}
{{- printf "%s:%s" .Values.image.repository $tag }}
{{- end }}

{{/* comfyui.modelsClaimName returns the PVC name for the models volume */}}
{{- define "comfyui.modelsClaimName" -}}
{{- .Values.persistence.existingClaim | default (printf "%s-models" (include "comfyui.fullname" .)) }}
{{- end }}

{{/* comfyui.outputClaimName returns the PVC name for generated output */}}
{{- define "comfyui.outputClaimName" -}}
{{- .Values.outputPersistence.existingClaim | default (printf "%s-output" (include "comfyui.fullname" .)) }}
{{- end }}

{{/* comfyui.userClaimName returns the PVC name for user state */}}
{{- define "comfyui.userClaimName" -}}
{{- .Values.userPersistence.existingClaim | default (printf "%s-user" (include "comfyui.fullname" .)) }}
{{- end }}

{{/* comfyui.inputClaimName returns the PVC name for uploaded inputs */}}
{{- define "comfyui.inputClaimName" -}}
{{- .Values.inputPersistence.existingClaim | default (printf "%s-input" (include "comfyui.fullname" .)) }}
{{- end }}

{{/* comfyui.tempClaimName returns the PVC name for temporary execution files */}}
{{- define "comfyui.tempClaimName" -}}
{{- .Values.tempPersistence.existingClaim | default (printf "%s-temp" (include "comfyui.fullname" .)) }}
{{- end }}

{{- define "comfyui.comfyMcpFullname" -}}
{{- printf "%s-mcp" (include "comfyui.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "comfyui.comfyMcpSelectorLabels" -}}
{{ include "comfyui.selectorLabels" . }}
app.kubernetes.io/component: comfy-mcp
{{- end }}
