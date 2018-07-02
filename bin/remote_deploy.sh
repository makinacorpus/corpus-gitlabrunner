#!/usr/bin/env bash
GRUNNER_TOP_DIR=$(dirname $(dirname  $(readlink -f $0)))
if [[ -z $TEST_COMMIT_REF_NAME ]] && [[ -z $TEST_ENVIRONMENT_NAME ]];then
    echo  "set at least TEST_ENVIRONMENT_NAME or TEST_COMMIT_REF_NAME" >&2
    exit 2
fi
if [[ -z $TEST_COMMIT_REF_NAME ]] && [[ -n $TEST_ENVIRONMENT_NAME ]];then
    export TEST_COMMIT_REF_NAME=${TEST_ENVIRONMENT_NAME-}-
fi
if [[ -n $TEST_COMMIT_REF_NAME ]] && [[ -z $TEST_ENVIRONMENT_NAME ]];then
    export TEST_ENVIRONMENT_NAME=${TEST_COMMIT_REF_NAME-}
fi
export TEST_COMMIT_REF_NAME=${TEST_COMMIT_REF_NAME-}
export TEST_ENVIRONMENT_NAME=${TEST_ENVIRONMENT_NAME-}

. $GRUNNER_TOP_DIR/bin/deploy_env

cd "$GRUNNER_TOP_DIR"

usage() {
    NO_HEADER=y die '
Run deploy procedure:
- Pushes project code inside
- Run its install procedure

 [NOCOLOR=y] \
 [NO_DEPLOY=y] \
 [NO_DT_SYNC=y] \
 [NO_SETUP=y] \
 [NO_DEPLOY_EXTRAS=y] \
 [TEST_PROJECT_PATH=/srv/projects/foo/project] \
 [TEST_COMMIT_REF_NAME=foobar] \
 [TEST_ENVIRONMENT_NAME=foobar] \
 [TEST_DEPLOY_PLAYBOOKS="ansible/fo.yml ansible/ba.yml"] \
 [DEBUG=y] \
    '"$0"'
 '
}
parse_cli() {
    parse_cli_common "${@}"
}
parse_cli "$@"
exec $GRUNNER_TOP_DIR/bin/deploy.sh \
    -e "{test_node: $TEST_COMMIT_REF_NAME, inc_node:  $TEST_COMMIT_REF_NAME}" \
    "$@"
# vim:set et sts=4 ts=4 tw=80:
