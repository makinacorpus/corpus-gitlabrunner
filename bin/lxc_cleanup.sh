#!/usr/bin/env bash
GRUNNER_TOP_DIR=$(dirname $(dirname  $(readlink -f $0)))
. $GRUNNER_TOP_DIR/bin/lxc_env

usage() {
    NO_HEADER=y die '
Cleanup container after tests

 [NOCOLOR=y] \
 [NO_CLEANUP=y] \
 [TEST_LXC_HOST=my.baremetal.net] \
 [TEST_LXC_NAME=mycontainer] \
 [TEST_LXC_PATH=/var/lib/lxc] \
 [TEST_LXC_CLEANUP_PLAYBOOKS="ansible/foo.yml ansible/bar.yml"] \
 [DEBUG=y] \
    '"$0"'
 '
}
parse_cli() { parse_cli_common "${@}"; }
parse_cli "$@"

if [[ -z $NO_CLEANUP ]];then
    ansible_play_vars="${TEST_ANSIBLE_VARS}" \
        vv silent_run ansible_play $TEST_LXC_CLEANUP_PLAYBOOKS
else
    warn "Skip cleanup step"
fi
ret=$?

exit ${ret}
# vim:set et sts=4 ts=4 tw=80:
