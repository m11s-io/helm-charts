{{- define "comfyui.modelsClaimName" -}}{{- .Values.persistence.existingClaim | default (printf "%s-models" (include "m11s-common.fullname" .)) -}}{{- end -}}
{{- define "comfyui.outputClaimName" -}}{{- .Values.outputPersistence.existingClaim | default (printf "%s-output" (include "m11s-common.fullname" .)) -}}{{- end -}}
{{- define "comfyui.userClaimName" -}}{{- .Values.userPersistence.existingClaim | default (printf "%s-user" (include "m11s-common.fullname" .)) -}}{{- end -}}
{{- define "comfyui.inputClaimName" -}}{{- .Values.inputPersistence.existingClaim | default (printf "%s-input" (include "m11s-common.fullname" .)) -}}{{- end -}}
{{- define "comfyui.tempClaimName" -}}{{- .Values.tempPersistence.existingClaim | default (printf "%s-temp" (include "m11s-common.fullname" .)) -}}{{- end -}}
{{- define "comfyui.comfyMcpFullname" -}}{{- printf "%s-mcp" (include "m11s-common.fullname" .) | trunc 63 | trimSuffix "-" -}}{{- end -}}

{{- define "comfyui.validateCustomNodes" -}}
{{- if .Values.customNodes.enabled -}}
{{- if not .Values.customNodes.repositories -}}
{{- fail "customNodes.enabled requires at least one repository" -}}
{{- end -}}
{{- $names := dict -}}
{{- $expected := list -}}
{{- range .Values.customNodes.repositories -}}
{{- if not (regexMatch "^[A-Za-z0-9][A-Za-z0-9_-]*$" .name) -}}
{{- fail "customNodes repository name must be a safe directory name" -}}
{{- end -}}
{{- if hasKey $names (lower .name) -}}{{- fail "customNodes repository names must be unique" -}}{{- end -}}
{{- $_ := set $names (lower .name) true -}}
{{- if not (regexMatch "^[a-fA-F0-9]{40}$" .revision) -}}{{- fail "customNodes revision must be a full commit hash" -}}{{- end -}}
{{- if not (regexMatch "^https://[^/@]+/[^ ?#]+$" .repository) -}}{{- fail "customNodes repository must be an HTTPS URL without credentials" -}}{{- end -}}
{{- if or (hasPrefix "/" (.requirements | default "")) (has ".." (splitList "/" (.requirements | default ""))) -}}
{{- fail "customNodes requirements must be a contained relative path" -}}
{{- end -}}
{{- $expected = concat $expected (.expectedNodes | default list) -}}
{{- end -}}
{{- range $key, $_ := .Values.customNodes.environment -}}
{{- if has $key (list "PATH" "PYTHONPATH" "PYTHONHOME" "VIRTUAL_ENV" "PIP_CONSTRAINT" "PIP_TARGET" "PIP_PREFIX" "PIP_USER") -}}
{{- fail (printf "customNodes.environment cannot override %s" $key) -}}
{{- end -}}
{{- end -}}
{{- if gt (len $expected) 0 -}}
{{- if or (not .Values.readinessProbe) (ne (dig "httpGet" "path" "" .Values.readinessProbe) "/system_stats") -}}
{{- fail "customNodes expectedNodes requires an HTTP /system_stats readinessProbe; its action is replaced by the node check" -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
