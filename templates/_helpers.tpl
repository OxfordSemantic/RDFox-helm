{{/*
Expand the name of the chart.
*/}}
{{- define "rdfox.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "rdfox.fullname" -}}
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

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "rdfox.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "rdfox.labels" -}}
helm.sh/chart: {{ include "rdfox.chart" . }}
{{ include "rdfox.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "rdfox.selectorLabels" -}}
app.kubernetes.io/name: {{ include "rdfox.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Selecting http vs https
*/}}
{{- define "rdfox.protocol"}}
{{- $channel := .Values.endpointParameters.channel }}
{{- if eq $channel "unsecure" -}}
http
{{- else if eq $channel "ssl" -}}
https
{{- else -}}
{{ fail "The endpoint parameter channel must be set to either 'unsecure' or 'ssl'" }}
{{- end }}
{{- end }}

{{/*
Validate persistence configuration
*/}}
{{- define "rdfox.validatePersistence" }}
{{- $serverParams := .Values.serverParameters }}
{{- $profile := index .Values.persistenceProfiles $serverParams.persistence }}

{{ if and (ne $serverParams.persistence "file") (ne $serverParams.persistence "file-sequence") }}
{{ fail "The server parameter persistence must be set to either 'file' or 'file-sequence'" }}
{{ end }}

{{- if not (hasKey .Values.persistenceProfiles $serverParams.persistence) }}
{{ fail "There is no configured persistenceProfiles matching the persistence type selected in .Values.serverParameters" }}
{{ end }}

{{ if and (gt ($profile.replicaCount | int) 1) (ne $serverParams.persistence "file-sequence") }}
{{ fail "persistence must be set to 'file-sequence' when the replicaCount is greater than 1" }}
{{ end }}
{{ end }}
