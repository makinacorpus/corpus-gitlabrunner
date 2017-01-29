{% set cfg = opts['ms_project'] %}
{% set data = cfg.data %}

include:
  - makina-projects.{{cfg.name}}.include.configs


