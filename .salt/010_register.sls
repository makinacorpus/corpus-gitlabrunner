{% import "makina-states/_macros/h.jinja" as h with context %}
{% set cfg = opts['ms_project'] %}
{% set data = cfg.data %}
{% set r = data.runner_config %}
{% set rs = r.runners %}

{% for runner, rcfg in cfg.data.runner_config.runners.items() %}
{% set ssh = rcfg.get('ssh', {}) %}
{% set tags = rcfg.get('tags_list', []) %}
{% set shell = rcfg.get('shell', 'bash') %}
{% set executor = rcfg.get('executor', 'shell') %}
register-runners-{{loop.index}}:
  cmd.run:
    - name: |
        gitlab-ci-multi-runner register -n \
            -c="/etc/gitlab-runner/config.toml" \
            -r "{{data.register_token}}" \
            --name="{{runner}}" \
            -u "{{rcfg.url}}" \
            --builds-dir="{{data.builds_dir}}" \
            --cache-dir="{{data.cache_dir}}" \
            --executor="{{executor}}" \
            \{% if tags%}
            --tag-list="{{",".join(tags)}}" {% endif%} \
            {% if executor=='shell' and shell %} --shell="{{shell}}"{%endif%} \
            {% if executor=='ssh' %} --ssh-host="{{ssh.host}}" --ssh-user="{{ssh.user}}" \
            {% if ssh.get('password', '') %} --ssh-password="{{ssh.password}}"{%endif%} \
            {% if ssh.get('identity_file', '') %} --ssh-identity-file="{{ssh.identity_file}}" \
            {%endif%} \
            {%endif%} \
            # end
    - unless: grep -q '  name = "{{runner}}"' "/etc/gitlab-runner/config.toml"
    - require_in:
        - cmd: {{cfg.name}}-service-register
{% endfor %}

{% if cfg.data.runner_config.runners %}
{{cfg.name}}-service-register:
  cmd.run:
    - name: |
        if test -e /etc/systemd/system/gitlab-runner.service ;then
          rm -f /etc/systemd/system/gitlab-runner.service
        fi
        if [ -e /etc/gitlab-runner/config.toml ];then
          gitlab-ci-multi-runner install \
            --config=/etc/gitlab-runner/config.toml \
            --service=gitlab-runner \
            --working-directory="{{data.runner_dir}}" \
            --user "gitlab-runner"
        fi
    - onlyif: |
        if [ ! -e /etc/systemd/system/gitlab-runner.service ];then
          exit 0
        fi
        if ! grep -q "{{data.builds_dir}}" /etc/systemd/system/gitlab-runner.service;then
          exit 0
        fi
        exit 1

{% macro rmacro() %}
    - watch:
      - cmd: {{cfg.name}}-service-register
{% endmacro %}
{{ h.service_restart_reload(
    'gitlab-runner',
     reload=False,
     enable=true,
     restart_macro=rmacro,
     force_restart=true) }}
{% else %}
{{cfg.name}}-service:
  service.dead:
    - name: gitlab-runner
    - enable: false
  file.absent:
    - require:
        - service: {{cfg.name}}-service
    - names:
        - /etc/systemd/system/gitlab-runner.service
        - /etc/gitlab-runner/config.toml
{% endif %}

