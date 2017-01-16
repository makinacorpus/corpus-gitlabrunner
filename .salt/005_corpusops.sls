{% set cfg = opts['ms_project'] %}
{% set data = cfg.data %}
cops-clone:
  mc_git.latest:
    - name: "https://github.com/corpusops/corpusops.bootstrap.git" 
    - target : /srv/corpusops/corpusops.bootstrap
cops-install:
  cmd.run:
    - name: /srv/corpusops/corpusops.bootstrap/bin/install.sh
    - unless: test -e /srv/corpusops/corpusops.bootstrap/venv/bin/ansible
    - use_vt: true
    - require:
        - mc_git: cops-clone
