#!/usr/bin/env bash
GRUNNER_TOP_DIR=$(dirname $(dirname  $(readlink -f $0)))
. $GRUNNER_TOP_DIR/bin/lxc_env

usage() {
    NO_HEADER=y die '
- Initialize a container from a template suitable for tests
- Pushes project code inside
- Run its install procedure

 [NOCOLOR=y] \
 [NO_BUILD=y] \
 [NO_CREATE=y] \
 [NO_SYNC=y] \
 [NO_DT_SYNC=y] \
 [NO_SETUP=y] \
 [TEST_LXC_HOST=my.baremetal.net] \
 [TEST_LXC_NAME=mycontainer] \
 [TEST_LXC_TEMPLATE=makinastates] \
 [TEST_LXC_PATH=/var/lib/lxc] \
 [TEST_PROJECT_PATH=/srv/foo] \
 [TEST_COMMIT=HEAD] \
 [TEST_LXC_BUILD_PLAYBOOKS="ansible/foo.yml ansible/bar.yml"] \
 [DEBUG=y] \
    '"$0"'
 '
}
parse_cli() { parse_cli_common "${@}"; }
parse_cli "$@"

if [[ -n $NO_BUILD ]];then
    warn "Skip build step"
    exit 0
fi

if [[ -z $NO_CREATE ]];then
    ansible_play_vars="${TEST_ANSIBLE_VARS}" \
        vv silent_run ansible_play $TEST_LXC_CREATE_PLAYBOOKS
    die_in_error "ansible playbook -create- failed"
else
    warn "Skip create step"
fi
if [[ -z $NO_DT_SYNC ]];then
    ansible_play_vars="${TEST_ANSIBLE_VARS}" \
        vv silent_run ansible_play $TEST_LXC_DT_SYNC_PLAYBOOKS
    die_in_error "ansible playbook -DT sync- failed"
else
    warn "Skip DT sync step"
fi
if [[ -z $NO_SYNC ]];then
    ansible_play_vars="${TEST_ANSIBLE_VARS}" \
        vv silent_run ansible_play $TEST_LXC_SYNC_CODE_PLAYBOOKS
    die_in_error "ansible playbook -sync- failed"
else
    warn "Skip sync code step"
fi
if [[ -z $NO_SETUP ]];then
    ansible_play_vars="${TEST_ANSIBLE_VARS}" \
        vv silent_run ansible_play $TEST_LXC_SETUP_PLAYBOOKS
    die_in_error "ansible playbook -setup- failed"
else
    warn "Skip setup step"
fi
exit 0
# vim:set et sts=4 ts=4 tw=80:
