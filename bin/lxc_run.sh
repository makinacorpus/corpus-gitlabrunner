#!/usr/bin/env bash
GRUNNER_TOP_DIR=$(dirname $(dirname  $(readlink -f $0)))
. $GRUNNER_TOP_DIR/bin/lxc_env

cd "$GRUNNER_TOP_DIR"

usage() {
    NO_HEADER=y die '
Create a container, install project, run tests, destroy container

 [NOCOLOR=y] \
 [NO_BUILD=y] \
 [NO_CREATE=y] \
 [NO_SYNC=y] \
 [NO_SETUP=y] \
 [NO_TEST=y] \
 [NO_CLEANUP=y] \
 [TEST_LXC_BUILD_SCRIPT=y] \
 [TEST_LXC_TEST_SCRIPT=y] \
 [TEST_LXC_CLEANUP_SCRIPT=y] \
 [TEST_LXC_HOST=my.baremetal.net] \
 [TEST_LXC_NAME=mycontainer] \
 [TEST_LXC_TEMPLATE=makinastates] \
 [TEST_LXC_PATH=/var/lib/lxc] \
 [DEBUG=y] \
    '"$0"'
 '
}

parse_cli() {
    parse_cli_common "${@}"
}
parse_cli "$@"

### Vuild
$TEST_LXC_BUILD_SCRIPT
ret=$?

### Tests
if [ "x${ret}" = "x0" ]; then
    echo here
    $TEST_LXC_TEST_SCRIPT
    ret=$?
else
    log "Build failed"
fi

### CLEANUP
$TEST_LXC_CLEANUP_SCRIPT
cleanup_ret=$?
if [ "x${cleanup_ret}" != "x0" ]; then
    log "Cleanup failed"
fi

###
if [ "x${ret}" != "x0" ]; then
    log "Tests failed"
fi
if [ "x${cleanup_ret}" != "x0" ] && [ "x${ret}" = "x0" ]; then
    log "Tests success but cleanup failed"
    ret=${cleanup_ret}
fi
exit ${ret}
# vim:set et sts=4 ts=4 tw=80:
