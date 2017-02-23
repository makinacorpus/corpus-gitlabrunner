{% set cfg = opts.ms_project %}
{% set data = cfg.data %}

include:
  - makina-states.services.base.ssh.client

{% if cfg.data.runner_config.runners %}
{{cfg.name}}-gci-repo:
  cmd.run:
    - name: |
        curl -L \
        https://packages.gitlab.com/install/repositories/runner/gitlab-ci-multi-runner/script.deb.sh \
        | sudo bash
    - onlyif: test ! -e /etc/apt/sources.list.d/runner_gitlab-ci-multi-runner.list

prepreqs-{{cfg.name}}:
  pkg.latest:
    - watch:
      - cmd: {{cfg.name}}-gci-repo
      {% if data.get('is_pg') %}
      - mc_proxy: ubuntugis-post-hardrestart-hook
      {% endif %}
    - pkgs: [gitlab-ci-multi-runner]
{{cfg.name}}-sudo:
  file.managed:
    - name: /etc/sudoers.d/{{cfg.user}}
    - contents: |
        {{cfg.user}} ALL=(ALL:ALL) NOPASSWD:ALL
        gitlab-runner ALL=(ALL:ALL) NOPASSWD:ALL
    - mode : 600
    - user: root
    - group: root
    - require_in:
      - file: {{cfg.name}}-dirs
{% endif %}

{{cfg.name}}-dirs:
  file.directory:
    - makedirs: true
    - user: gitlab-runner
    - group: gitlab-runner
    - names:
      - {{data.builds_dir}}
      - {{data.cache_dir}}

