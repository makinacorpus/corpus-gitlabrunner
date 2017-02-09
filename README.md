# gitlab runner configuration with makina-states

## SPEC
### The big picture
```
    GITLAB <- HTTP -> gitlab runners nodes with LXC preconfigured -> container1
                               |                                         |
                               |- -- Ansible/SSH via compute node  ------|
```
Where ever we have SSH or a local shell account, we can easily use ansible to execute remote tasks.
Idea is to execute tests on volatile containers spinned on remote lxc-capable compute nodes via the gitlabrunner node.

### Test infra description
- We install a gitlabrunner somewhere
- This runner can connect as root via ssh to hosts than can spin lxc containers
  - To preconfigure lxc hosting, we use: [virt_lxc](https://github.com/corpusops/services_virt_lxc)
- As soon as we spin a lxc container we can control it via SSH
  - We use here [lxc_create](https://github.com/corpusops/lxc_create)
  - & [lxc_sshauth](https://github.com/corpusops/lxc_sshauth)
- We can then spin lxc containers and run our test suite on. All this work is done and configurable
  via well placed ansible playbooks and shell scripts that call them
  - Read (recursivly [this run script](./bin/lxc_run.sh).
    This will executes some phases.
    - 1. [lxc_build.sh](./bin/lxc_build.sh): create a container and prepare it for tests. <br/>
         It is in charge to call in order those playbooks:
        - [lxc/create.yml](./ansible/playbooks/lxc/create.yml): create a container from a template
        - [lxc/sync_code.yml](./ansible/playbooks/lxc/lifecycle/sync_code.yml): synchronise code inside the environment
           - itself calls: [lifecycle/sync_code.yml](./ansible/playbooks/lifecycle/sync_code.yml)
        - [lxc/setup.yml](./ansible/playbooks/lxc/lifecycle/setup.yml): run project setup procedure
           - itself calls: [lifecycle/setup.yml](./ansible/playbooks/lifecycle/setup.yml)
    - 2. [lxc_test.sh](./bin/lxc_test.sh): Call project tests.<br/>
        It is in charge to call in order those playbooks:
        - [lxc/test.yml](./ansible/playbooks/lxc/lifecycle/test.yml): run project tests
           - itself calls: [lifecycle/test.yml](./ansible/playbooks/lifecycle/test.yml)
    - 3. [lxc_cleanup.sh](./bin/lxc_cleanup.sh): cleanup test resources <br/>
         It is in charge to call in order those playbooks
        - [lxc/cleanup.yml](./ansible/playbooks/lxc/cleanup.yml): remove whatever we did on the baremetal.
          Barely, and for now, this resumes at dropping the test container.

### Services activated on templates:
- memcached
- mysql:
  - root password: secret
  - db0 -> db9, user & password are the same as the database.
- elasticsearch:
  - http://127.0.0.1:9200
  - no restriction
- redis
- pgsql
  - local user postgres is superuser
  - db0 -> db9, user & password are the same as the database
- mongodb (**TODO**)
  - db0 -> db9, user & password are the same as the database
- selenium, firefox, xvfb


## Install this project on the gitlabrunner

### install makina-states
The gitlab runner must have ssh root access to a compute node where to execute lxc containers.
```sh
git clone https://github.com/makinacorpus/makina-states.git /srv/makina-states
/srv/makina-states/bin/boot-salt2.sh --install-links
salt-call mc_project.init_project gitlabrunner
```

### install project
```sh
cd /srv/projects/gitlabrunner/project
git remote add g https://github.com/makinacorpus/corpus-gitlabrunner
git fetch --all
git reset --hard g/master
$EDITOR ../pillar/init.sls
salt-call mc_project.deploy gitlabrunner only=install,fixperms
```

You may not configure runners, in this case gitlab runner wont be installed, only corpusops.

This can be useful to grab the scripts to setup LXC computes nodes controlled by a distant runner.

#### example pillar without configuring a runner
```yaml
makina-projects.gitlabrunner:
  api_version: '2'
  data: {}
```

#### example pillar with configuring a runner
Shell
```yaml
makina-projects.gitlabrunner:
  api_version: '2'
  data:
    register_token: "xxx"
    runner_config:
      runners:
        "zzz.foo.net":
          url: "https://gitlab.foo.net"
          tags_list: ["lxc_python", "makina-states", "zzz.foo.net"]
```

SSH
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
          tags_list: ["lxc", "makina-states"]
          ssh:
            user: "root"
            host: "zzz.makina-corpus.net"
            identity_file: "/home/users/gitlabrunner-user/.ssh/id_rsa"
```

## Setup gitlab runner nodes

### setup each compute node
install lxc
```sh
host=host.foo.net
bin/ansible-playbook-wrapper -i $host, \
  /srv/corpusops/corpusops.bootstrap/roles/corpusops.services_virt_lxc/role.yml
```

### drupal & python templates
You can contruct templates via ansible playbooks we baked with this project:
```sh
host=localhost
for i in python drupal;do
  TEST_LXC_NAME=gitlabrunner-$i
  bin/ansible-playbook-wrapper -i $host, ansible/playbooks/lxc/create.yml \
    -e "TEST_LXC_HOST=$host TEST_LXC_NAME=$TEST_LXC_NAME"
  bin/ansible-playbook-wrapper -i $host, ansible/playbooks/lxc/provision/node_${i}.yml \
    -e "TEST_LXC_HOST=$host TEST_LXC_NAME=$TEST_LXC_NAME"
done
```
After provision, make sure the template is not running and in ``/var/lib/lxc/$container/config``: ``lxc.start.auto=0``
```sh
for i in gitlabrunner-lxc gitlabrunner-python;do
  lxc-stop -k -n $lxc
  sed -i -re "s/lxc.start.auto =.*/lxc.start.auto = 0/g" -i /var/lib/lxc/$lxc/config
done
```
## Add ci to a gitlab project

## Customizing the build
Most of the procedure can be modified for a project by simply copying and
adapting playbooks inside your project repository.

### Customizing the template
The most important thing to choose when you ll start to put your project under CI
is the ancestor container to spin a new container with.<br/>
This is done via the ``TEST_LXC_TEMPLATE`` environment variable:
A good value could be:
- gitlabrunner-python
- gitlabrunner-drupal

But any preexisting and stopped container present on your CI LXC node can be used as a template.

### Configuring your test suite
Place a ``$project_dir/ansible/playbooks/tests/test.yml`` ansible playbook file which looks like
[this one](./ansible/playbooks/lxc/lifecycle/standalone_test.yml)

### Skipping steps
You can skip each step of the procedure via the relevant **NO_XXX** environment variable:
- ``NO_CLEANUP``: Skip the cleanup step
- ``NO_TEST``: Skip the tests step
- ``NO_CREATE``: Skip the create step
- ``NO_CLEANUP``: Skip the cleanup step
- ``NO_SYNC``: Skip the synchronise code step
- ``NO_BUILD``: Skip the build step

### Changing the top level step executors (the lxc_{build,run,cleanup}.sh scripts)
Top level scripts paths can be overriden by changing their path via their relevant **XXX_SCRIPT** envionment variables:
- ``TEST_LXC_BUILD_SCRIPT``: script to exec at build step, default: [bin/lxc_build.sh](bin/lxc_build.sh)
- ``TEST_LXC_TEST_SCRIPT ``: script to exec at test step, default: [bin/lxc_test.sh](bin/lxc_test.sh)
- ``TEST_LXC_CLEANUP_SCRIPT``: script to exec at cleanup step , default: [bin/lxc_cleanup.sh](./bin/lxc_cleanup.sh)

### Changing the playbooks
- Playbooks can also be found (understand you can override them by placing an edited copy) in
    - ``$PROJECT_REPO/ansible/tests``
    - ``$PROJECT_REPO/.ansible/tests``
    - Example to override the **setup.step**, place a **setup.yml** playbook
      in ``$PROJECT/.ansible/playbooks/tests`` that overrides **lxc/setup.yml**.


Playbooks environment variables (space separated list of playbooks (filename)):
- ``TEST_LXC_CREATE_PLAYBOOKS``: playbooks to run at create step (**<first_found>/create.yml**)
- ``TEST_LXC_SYNC_CODE_PLAYBOOKS ``: playbooks to run at sync. code step (**<first_found>/sync_code**)
- ``TEST_LXC_SETUP_PLAYBOOKS``: playbooks to run at setup  step (**<first_found>/setup.yml**)
- ``TEST_LXC_TEST_PLAYBOOKS``: playbooks to run at test step (**<first_found>/test.yml**)
- ``TEST_LXC_CLEANUP_PLAYBOOKS``:  playbooks to run at cleanup step (**<first_found>/cleanup.yml**)
- If not overriden, each playbook will be seeked in this order:
    -  ``$project/.ansible/playbooks/tests``
    -  ``$project/ansible/playbooks/tests``
    -  ``$thisrepo/<default_location>``

### .gitlab-ci.yml Examples
- [dummy](./examples/dummy-.gitlab-ci.yml)
- [django](https://github.com/makinacorpus/corpus-django/blob/master/.gitlab-ci.yml)
- [zope](https://github.com/makinacorpus/corpus-zope-plone/blob/master/.gitlab-ci.yml)
- [drupal](https://github.com/makinacorpus/corpus-drupal/blob/master/.gitlab-ci.yml)

### ENVIRON
Main variables that you can override in your ``.gitlab-ci.yml`` environment section to parameterize the build

All those variables are exported with same name to ansible
Additionnaly, you also have access to the [gitlab exported variables](https://docs.gitlab.com/ce/ci/variables/).

To be clear any variable under the {RESTORE|ARTIFACT,GET,CI,GITLAB,CUSTOM}_ prefixes are exported.
If you need to use gitlab variables, name them like ``CUSTOM_XXX``. If this really isnt convenient, redefine the ``TEST_FORWARDED_SHELL_VARS`` environ variable to something more appropriate.

| NAME                         | DESC                              |  DEFAULT or Example        |
| ---------------------------- | --------------------------------- |  -------------------------------            |
| GRUNNER_TOP_DIR        | root path of this repo     | /srv/projects/gitlabrunner/project |
| **TEST_LXC_TEMPLATE**        | container to take as ancestor     |  gitlabrunner-common                        |
| TEST_USE_MAKINASTATES        | is the project makinastates based |  true                                       |
| TEST_COMMIT        | deployed commit |  true                                       |
| TEST_LXC_NAME                | name of the container to create   |  gci-$(get_random_slug 8)                   |
| TEST_LXC_BUILD_SCRIPT        | script to exec at build step      |  [bin/lxc_build.sh](bin/lxc_build.sh)       |
| TEST_LXC_TEST_SCRIPT         | script to exec at test step       |  [bin/lxc_test.sh](bin/lxc_test.sh)         |
| TEST_LXC_CLEANUP_SCRIPT      | script to exec at cleanup step    |  [bin/lxc_cleanup.sh](./bin/lxc_cleanup.sh) |
| TEST_LXC_HOST                | host to create containers on      |  10.5.0.1                                   |
| TEST_LXC_PATH                | path of the containers root       |  /var/lib/lxc                               |
| TEST_LXC_BACKING_STORE       | backing store for container       |  overlayfs                                  |
| TEST_ORIGIN                  | from where to push sources inside the test env | gitlab ci host (localhost)     |
| TEST_ORIGIN_PATH             | sources to push inside the test env            | gitlab ci checkout root        |
| TEST_PROJECT_PATH            | where to push sources inside test env          | /srv/projects/project/project} |
| TEST_PILLAR_FILENAME         | project pillar to load from .salt folder       | PILLAR.test |
| TEST_FORWARDED_SHELL_VARS    | regex for variables to export through the build procedure | <pre>^(W|GRUNNER_TOP_DIR|(CUSTOM|GITLAB|ARTIFACT|RESTORE|GET|TEST|NO|CI)_.*)$</pre> |
| NO_BUILD                     | Skip the build step            | not defined |
| NO_CREATE                    | Skip the create step           | not defined |
| NO_SYNC                      | Skip the synchronise code step | not defined |
| NO_SETUP                     | Skip the setup code step | not defined |
| NO_TEST                      | Skip the tests step            | not defined |
| NO_CLEANUP                   | Skip the cleanup step          | not defined |
| TEST_LXC_CREATE_PLAYBOOKS    | space separated abspaths to playbooks to run at create step     | <fist_found>/create.yml   |
| TEST_LXC_SYNC_CODE_PLAYBOOKS | space separated abspaths to playbooks to run at sync. code step | <fist_found>/sync_code.yml|
| TEST_LXC_SETUP_PLAYBOOKS     | space separated abspaths to playbooks to run at setup  step     | <fist_found>/setup.yml    |
| TEST_LXC_TEST_PLAYBOOKS      | space separated abspaths to playbooks to run at test step       | <fist_found>/test.yml     |
| TEST_LXC_CLEANUP_PLAYBOOKS   | space separated abspaths to playbooks to run at cleanup step    | <fist_found>/cleanup.yml  |
| TEST_SALTCALL_LOGLEVEL   | salt-call loglevel | info  |

