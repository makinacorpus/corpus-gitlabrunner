{% set cfg = opts['ms_project'] %}
{% set data = cfg.data %}
{% set r = data.runner_config %}
{% set rs = r.runners %}

{% for runner, rcfg in cfg.data.runner_config.runners.items() %}
{% set ssh = rcfg.get('ssh', {}) %}
{% set tags = rcfg.get('tags_list', []) %}
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
            --executor="{{rcfg.executor}}" \
            \{% if tags%}
            --tag-list="{{",".join(tags)}}"\
            {% endif%} \
            \{% if rcfg.executor=='ssh' %}
            --ssh-host="{{ssh.host}}" \
            --ssh-user="{{ssh.user}}" \
            {% if ssh.get('password', '') %}--ssh-password="{{ssh.password}}"{%endif%} \
            {% if ssh.get('identity_file', '') %}--ssh-identity-file="{{ssh.identity_file}}"{%endif%} \
            {%endif%} \
    - unless: grep -q '  name = "{{runner}}"' "/etc/gitlab-runner/config.toml"
{% endfor %}

