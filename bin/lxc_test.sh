#!/usr/bin/env bash
GRUNNER_TOP_DIR=$(dirname $(dirname  $(readlink -f $0)))
. $GRUNNER_TOP_DIR/bin/lxc_env

usage() {
    NO_HEADER=y die '
Executes tests inside a setup-ed container

 [NOCOLOR=y] \
 [NO_TEST=y] \
 [TEST_LXC_HOST=my.baremetal.net] \
 [TEST_LXC_NAME=mycontainer] \
 [TEST_LXC_TEMPLATE=makinastates] \
 [TEST_LXC_PATH=/var/lib/lxc] \
 [TEST_PROJECT_PATH=/srv/projects/project/project] \
 [TEST_COMMIT=HEAD] \
 [TEST_LXC_TEST_PLAYBOOKS="ansible/foo.yml ansible/bar.yml"] \
 [DEBUG=y] \
    '"$0"'
 '
}
parse_cli() { parse_cli_common "${@}"; }
parse_cli "$@"

if [[ -z $NO_TEST ]];then
    ansible_play_vars="${TEST_ANSIBLE_VARS}" \
        vv ansible_play $TEST_LXC_TEST_PLAYBOOKS
else
    warn "Skip test step"
fi
ret=$?

exit ${ret}
# vim:set et sts=4 ts=4 tw=80:
