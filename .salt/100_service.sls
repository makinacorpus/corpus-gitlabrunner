{% import "makina-states/_macros/h.jinja" as h with context %}
{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
{{ h.service_restart_reload(
    'gitlab-runner', enable=true, force_restart=true) }}
