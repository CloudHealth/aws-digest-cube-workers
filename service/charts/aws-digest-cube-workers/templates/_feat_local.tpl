{{/* Service-local settings.

After editing this file, run

  ~/src/cht-ng/cht-helm-common/bootstrap.sh

to regenerate the values.yaml file and anything else you change.

https://github.com/CloudHealth/cht-helm-common/blob/develop/doc/REFERENCE.md
has a listing of the things you can control here.

*/}}

{{/* The set of parts this file provides.  Each of these corresponds
to a "cht.*.local" template later in the file. */}}
{{- define "cht.parts.aws-digest-local" -}}
values env mount volume
{{- end -}}

{{/* Fragment of the values.yaml file.  Any text specified here is inserted
into the chart's values.yaml file when the bootstrap.sh script is run
again.  This needs to preserve any existing values.  Consider patterns like

someValue: {{ .Values.someValue | default "theDefault" }}
{{ template "cht.optvalue" (list "optionalValue" .Values "commented out") }}

*/}}
{{- define "cht.values.aws-digest-local" -}}

# containerRedis describes a Redis server for general container cp cache
containerRedis:
{{- $cntr := .Values.containerRedis | default dict }}
  {{ template "cht.optvalue" (list "host" $cntr "redis") }}
  port: {{ $cntr.port | default 6379 }}

{{ end -}}

{{- define "cht.mount.aws-digest-local" -}}
- mountPath: /root/cp-workers/config
  name: configs
- mountPath: /root/cp-workers/log
  name: log
- mountPath: /root/cp-workers/tmp
  name: tmp
- mountPath: /root/cp-workers/tmpa
  name: tmpa
- mountPath: /root/cp-workers/analysis_store
  name: analysis-store
{{- end -}}


{{- define "cht.volume.aws-digest-local" -}}
- name: configs
  projected:
    sources:
    {{- if eq .Values.component "cur-availability-immutable" }}
    - secret:
        name: {{ $.Release.Name }}-cur-availability-immutable-config
    {{ end -}}
    {{- if eq .Values.component "cubes-immutable" }}
    - secret:
        name: {{ $.Release.Name }}-cubes-immutable-config
    {{ end -}}
    {{- if eq .Values.component "cubes-partnerds" }}
    - secret:
        name: {{ $.Release.Name }}-cubes-partnerds-config
    {{ end -}}
    {{- if eq .Values.component "cubinator-graviton-cattle" }}
    - secret:
        name: {{ $.Release.Name }}-cubinator-graviton-cattle-config
    {{ end -}}    
    {{- if eq .Values.component "cubinator-graviton-mammoth" }}
    - secret:
        name: {{ $.Release.Name }}-cubinator-graviton-mammoth-config
    {{ end -}}
    {{- if eq .Values.component "cubinator-graviton-whale" }}
    - secret:
        name: {{ $.Release.Name }}-cubinator-graviton-whale-config
    {{ end -}}       
    {{- if eq .Values.component "azure-graviton" }}
    - secret:
        name: {{ $.Release.Name }}-azure-graviton-config
    {{ end -}}        
    - secret:
        name: {{ .Release.Name }}-config
- name: log
  emptyDir: {}
- name: tmp
  emptyDir: {}
- name: tmpa
  emptyDir: {}
- name: analysis-store
  emptyDir: {}
{{- end }}


*/}}
{{- define "cht.env.aws-digest-local" -}}
- name: RAILS_ENV
  value: {{ .Values.rails.environment }}
{{ end -}}

{{- define "cht.component.args" -}}
{{- $top := index . 0 -}}
{{- $component := index . 1 -}}
command:
    - "/bin/bash"
    - "-c"
    - {{ $component.command }}
{{- end -}}
