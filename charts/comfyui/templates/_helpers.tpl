{{- define "comfyui.modelsClaimName" -}}{{- .Values.persistence.existingClaim | default (printf "%s-models" (include "m11s-common.fullname" .)) -}}{{- end -}}
{{- define "comfyui.outputClaimName" -}}{{- .Values.outputPersistence.existingClaim | default (printf "%s-output" (include "m11s-common.fullname" .)) -}}{{- end -}}
{{- define "comfyui.userClaimName" -}}{{- .Values.userPersistence.existingClaim | default (printf "%s-user" (include "m11s-common.fullname" .)) -}}{{- end -}}
{{- define "comfyui.inputClaimName" -}}{{- .Values.inputPersistence.existingClaim | default (printf "%s-input" (include "m11s-common.fullname" .)) -}}{{- end -}}
{{- define "comfyui.tempClaimName" -}}{{- .Values.tempPersistence.existingClaim | default (printf "%s-temp" (include "m11s-common.fullname" .)) -}}{{- end -}}
{{- define "comfyui.comfyMcpFullname" -}}{{- printf "%s-mcp" (include "m11s-common.fullname" .) | trunc 63 | trimSuffix "-" -}}{{- end -}}
