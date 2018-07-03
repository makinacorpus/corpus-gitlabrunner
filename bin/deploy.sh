#!/usr/bin/env bash
GRUNNER_TOP_DIR=$(dirname $(dirname  $(readlink -f $0)))

. $GRUNNER_TOP_DIR/bin/deploy_env

cd "$GRUNNER_TOP_DIR"

usage() {
    NO_HEADER=y die '
Run deploy procedure:
- Pushes project code inside
- Run its install procedure

 [NOCOLOR=y] \
 [NO_DEPLOY=y] \
 [NO_KEY_SETUP=y] \
 [NO_DT_SYNC=y] \
 [NO_SETUP=y] \
 [NO_DEPLOY_EXTRAS=y] \
 [TEST_PROJECT_PATH=/srv/projects/foo/project] \
 [TEST_COMMIT=HEAD] \
 [TEST_DEPLOY_PLAYBOOKS="ansible/fo.yml ansible/ba.yml"] \
 [DEBUG=y] \
    '"$0"'
 '
}

parse_cli() {
    parse_cli_common "${@}"
}
parse_cli "$@"
if [[ -n $NO_DEPLOY ]];then
    warn "Skip build step"
    exit 0
fi

### SYNC CODE

if [[ -z $NO_KEY_SETUP ]];then
    ansible_play_vars="${TEST_ANSIBLE_VARS}" \
    vv silent_run ansible_play_one \
        "$GRUNNER_TOP_DIR/ansible/playbooks/lifecycle/setup_sshkeys.yml"
    die_in_error "ansible playbook -sshkey- failed"
else
    warn "Skip ssh key setup"
fi
if [[ -z $NO_DT_SYNC ]];then
    for i in $TEST_DT_SYNC_PLAYBOOKS;do
        ansible_play_vars="${TEST_ANSIBLE_VARS}" \
            vv silent_run ansible_play_one "$i" "${@}"
        die_in_error "ansible playbook -DT sync- failed: $i"
    done
else
    warn "Skip sync DT step"
fi

### SYNC
if [[ -z $NO_SYNC ]];then
    for i in $TEST_SYNC_CODE_PLAYBOOKS;do
        ansible_play_vars="${TEST_ANSIBLE_VARS}" \
            vv silent_run ansible_play_one "$i" "${@}"
        die_in_error "ansible playbook -sync- failed: $i"
    done
else
    warn "Skip sync code step"
fi

### SETUP
if [[ -z $NO_SETUP ]];then
    for i in $TEST_ENV_SETUP_PLAYBOOKS;do
        ansible_play_vars="${TEST_ANSIBLE_VARS}" \
            vv silent_run ansible_play_one "$i" "${@-}"
        die_in_error "ansible playbook -setup- failed: $i"
    done
else
    warn "Skip setup step"
fi

### EXTRAS/POST
if [[ -z $NO_DEPLOY_EXTRAS ]];then
    if [[ -n ${TEST_DEPLOY_PLAYBOOKS-} ]];then
        for i in ${TEST_DEPLOY_PLAYBOOKS:-};do
            ansible_play_vars="${TEST_ANSIBLE_VARS}" \
                vv silent_run ansible_play_one "${i}" "${@}"
            die_in_error "ansible playbook -${i}- failed"
        done
    fi
else
    warn "Skip additionnal playbooks step"
fi

log "Deploy success"
# vim:set et sts=4 ts=4 tw=80:
