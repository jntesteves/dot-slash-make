# SPDX-License-Identifier: Unlicense
# {{{PackageConfig_getProperty '' VERSION}}}
# shellcheck shell=sh
#
# This file is part of dot-slash-make https://codeberg.org/jntesteves/dot-slash-make
# Do NOT make changes to this file, your commands go in the ./make file
#
#{{{ strict_mode }}}
#{{{
import \
	"{ log_error, log_warn, log_info, log_debug, log_trace, log_is_level }" from nice_things/log/log.sh \
	"{ abort }" from nice_things/log/abort.sh \
	"{ length, is_list, to_string, list, list_from }" from nice_things/collections/native_list.sh \
	"{ fmt }" from nice_things/collections/native_list_fmt.sh \
	"{ glob }" from nice_things/fs/glob.sh \
	"{ echo }" from nice_things/io/echo.sh \
	"{ assign }" from nice_things/lang/assign.sh \
	"{ assign_variable }" from nice_things/lang/assign_variable.sh
#}}}
# main.sh

# Run command in a sub-shell, abort on error
run() {
	log_info "$@"
	("$@") || abort "${0}: [target: ${__target__}] Error ${?}"
}

# Run command in a sub-shell, ignore returned status code
_run() {
	log_info "$@"
	("$@") || log_warn "${0}: [target: ${__target__}] Error ${?} (ignored)"
}

# Check if the given name was provided as an argument in the CLI
NS__is_in_cli_parameters_list() {
	# shellcheck disable=SC2086
	log_trace "dot-slash-make: [NS__is_in_cli_parameters_list] var_name='${1}' NS__cli_parameters='$(to_string $NS__cli_parameters)'"
	for NS__arg in $NS__cli_parameters; do
		if [ "$1" = "$NS__arg" ]; then return 0; fi
	done
	unset -v NS__arg
	return 1
}

NS__set_variable_cli_override() {
	NS__var_name="${2%%=*}"
	if [ "$1" ] && NS__is_in_cli_parameters_list "$NS__var_name"; then
		log_debug "dot-slash-make: [${1}] '${NS__var_name}' overridden by command line argument"
		return 0
	fi
	assign_variable "$2" || abort "${0}:${1:+" [$1]"} Invalid parameter name '${NS__var_name}'"
	# shellcheck disable=SC2086
	[ "$1" ] || NS__cli_parameters=$(list $NS__cli_parameters "$NS__var_name")
	eval "log_debug \"dot-slash-make: [${1:-NS__set_variable_cli_override}] ${NS__var_name}=\$${NS__var_name}\""
	unset -v NS__var_name
}

# Set variable from argument NAME=VALUE, only if it was not overridden by an argument on the CLI
param() { NS__set_variable_cli_override param "$@"; }

# Perform Tilde Expansion and Pathname Expansion (globbing) on arguments
# Similar behavior as the wildcard function in GNU Make
wildcard() {
	NS__wildcard_buffer=
	for NS__wildcard_pattern in "$@"; do
		case "$NS__wildcard_pattern" in
		"~") NS__wildcard_pattern=$HOME ;;
		"~"/*) NS__wildcard_pattern="${HOME}${NS__wildcard_pattern#"~"}" ;;
		esac
		# shellcheck disable=SC2046,SC2086
		NS__wildcard_buffer=$(list $NS__wildcard_buffer $(glob "$NS__wildcard_pattern")) || return
	done
	printf '%s' "$NS__wildcard_buffer"
	unset -v NS__wildcard_buffer NS__wildcard_pattern
}

NS__shift_targets_() {
	if [ $# -eq 0 ]; then return 1; fi
	__target__=$1
	shift
	NS__targets_list_=$(list "$@")
}
# shellcheck disable=SC2086
next_target() { NS__shift_targets_ $NS__targets_list_; }

NS__cli_parameters=
NS__targets_list_=
__target__=
while [ "$#" -gt 0 ]; do
	case "$1" in
	--) ;;
	-?*) abort "${0}: Unknown option '${1}'" ;;
	[_a-zA-Z]*=*) NS__set_variable_cli_override '' "$1" ;;
	*)
		# shellcheck disable=SC2086
		NS__targets_list_=$(list ${NS__targets_list_} "$1")
		;;
	esac
	shift
done
[ "$NS__targets_list_" ] || NS__targets_list_=-
# shellcheck disable=SC2086
log_debug "dot-slash-make: [main] NS__targets_list_=$(to_string ${NS__targets_list_})"
