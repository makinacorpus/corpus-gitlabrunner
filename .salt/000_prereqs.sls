{% set cfg = opts.ms_project %}
{% set data = cfg.data %}

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

{% if 'lxc' in data.modes %}
{{cfg.name}}-lxc-ci:
  mc_git.latest:
    - target: /srv/gitlabci-lxc/
    - name: "https://github.com/makinacorpus/gitlabci-lxc.git"
    - rev: master
{% endif %}

{{cfg.name}}-sudo:
  file.managed:
    - name: /etc/sudoers.d/{{cfg.user}}
    - contents: |
        {{cfg.user}} ALL=(ALL:ALL) NOPASSWD:ALL
    - mode : 600
    - user: root
    - group: root

{{cfg.name}}-service:
  cmd.run:
    - name: |
        if test -e /etc/systemd/system/gitlab-runner.service ;then
          rm -f /etc/systemd/system/gitlab-runner.service
        fi
        gitlab-ci-multi-runner install \
          --config=/etc/gitlab-runner/config.toml \
          --service=gitlab-runner \
          --working-directory="{{data.builds_dir}}" \
          --user "{{cfg.user}}"
    - onlyif: |
        if [ ! -e /etc/systemd/system/gitlab-runner.service ];then
          exit 0
        fi
        if ! grep -q "{{data.builds_dir}}" /etc/systemd/system/gitlab-runner.service;then
          exit 0
        fi
        exit 1
    - require:
      - file: {{cfg.name}}-sudo

{{cfg.name}}-dirs:
  file.directory:
    - makedirs: true
    - user: {{cfg.user}}
    - group: {{cfg.group}}
    - watch:
      - pkg: prepreqs-{{cfg.name}}
    - names:
      - {{data.builds_dir}}
      - {{data.cache_dir}}


