{% set cfg = opts['ms_project'] %}
{% set data = cfg.data %}

# reconfigure runner after register only !
include:
  - makina-projects.{{cfg.name}}.include.configs


