#!/usr/bin/env bash
GRUNNER_TOP_DIR=$(dirname $(dirname  $(readlink -f $0)))
. $GRUNNER_TOP_DIR/bin/shell_common
if get_all_variables | grep -q TEST_LXC; then
    . $GRUNNER_TOP_DIR/bin/lxc_env
fi

cd "$GRUNNER_TOP_DIR"

usage() {
    NO_HEADER=y die '
Print CI related variables

 [NOCOLOR=y] \
 [DEBUG=y] \
    '"$0"'
 '
}

parse_cli() {
    parse_cli_common "${@}"
}
parse_cli "$@"
re_export_vars
print_env_vars
# vim:set et sts=4 ts=4 tw=80:
