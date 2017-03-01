# Setup a CD runner
The CD runners only requirement is to provide a shell/ssh executor based gitlabrunner.


## Setup a vault for the environment on your project
You will need to add a vault environment file inside the project code source repo.<br/>
See the appropriate section in [CD](./cd.md)

## Setup the vault passphrase
You will need to write the vault passphase<br/>
See the appropriate section in [CD](./cd.md)

## Setup and link the runner to gitlab
See [common setup](./install_runner.md)

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
            - "makina-states"
          ssh:
            user: "root"
            host: "zzz.makina-corpus.net"
            identity_file: "/home/users/gitlabrunner-user/.ssh/id_rsa"
```

