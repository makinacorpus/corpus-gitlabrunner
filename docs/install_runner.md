# Common setup for runners
## install makina-states
```sh
git clone https://github.com/makinacorpus/makina-states.git /srv/makina-states
/srv/makina-states/bin/boot-salt2.sh -C --install-links
```

## install project (will also install corpusops)
You may not configure runners, in this case gitlab runner wont be installed, only corpusops will.
This can be useful to grab the scripts to setup LXC compute nodes controlled by a distant runner.

Example setup script
```sh
salt-call mc_project.init_project gitlabrunner remote_less=True
cd /srv/projects/gitlabrunner/project
git remote add g https://github.com/makinacorpus/corpus-gitlabrunner
git fetch --all;git reset --hard g/master
if [ ! -e ../pillar/init.sls ];then cp .salt/PILLAR.test ../pillar/init.sls;fi
# If the runner is only a CD runner
sed -i -re "/- lxc_/d"  ../pillar/init.sls # will remove the lxc_tags
$EDITOR ../pillar/init.sls # at least change the token, see below for examples
salt-call mc_project.deploy gitlabrunner only=install,fixperms
```

## example pillar with configuring a runner for Shell executor
```yaml
makina-projects.gitlabrunner:
  api_version: '2'
  data:
    register_token: "xxx"
    runner_config:
      runners:
        "zzz.foo.net":
          url: "https://gitlab.foo.net"
          tags_list:
            - "lxc_python"
            - "makina-states"
            - "zzz.foo.net"
```

## example pillar with configuring a runner for SSH executor
```yaml
makina-projects.gitlabrunner:
  api_version: '2'
  data:
    register_token: "xxx"
    runner_config:
      runners:
        "zzz.foo.net (CI)":
          url: "https://gitlab.foo.net"
          executor: "ssh"
          tags_list:
            - "lxc_python"
            - "makina-states"
          ssh:
            user: "root"
            host: "zzz.makina-corpus.net"
            identity_file: "/home/users/gitlabrunner-user/.ssh/id_rsa"
```

## example pillar without configuring a runner
```yaml
makina-projects.gitlabrunner:
  api_version: '2'
  data: {}
```
