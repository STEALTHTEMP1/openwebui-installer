{{/* Generate a name */}}
{{- define "openwebui.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Generate a fullname */}}
{{- define "openwebui.fullname" -}}
{{- printf "%s-%s" (include "openwebui.name" .) .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
