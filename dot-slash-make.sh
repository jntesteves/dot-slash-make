# SPDX-License-Identifier: Unlicense
# v0.1.0-pre
# shellcheck shell=sh
#
# This file is part of dot-slash-make https://codeberg.org/jntesteves/dot-slash-make
# Do NOT make changes to this file, your commands go in the ./make file
#
log_error() (IFS=' ' && printf 'ERROR %s\n' "$*" >&2)
log_warn() (IFS=' ' && printf 'WARN %s\n' "$*" >&2)
log_info() (IFS=' ' && printf '%s\n' "$*")
log_debug() { :; } && [ "$MAKE_DEBUG" ] && log_debug() (IFS=' ' && printf 'DEBUG %s\n' "$*")
log_trace() { :; } && case "$MAKE_DEBUG" in *trace*) log_trace() (IFS=' ' && printf 'TRACE %s\n' "$*") ;; esac
abort() {
	log_error "$@"
	exit 1
}

# Get real path to shell interpreter of current process
real_proc_cmdline() (
	if [ -r /proc/$$/cmdline ]; then
		proc_cmdline="$(cut -d '' -f1 /proc/$$/cmdline 2>/dev/null)" || return 1
	else
		proc_cmdline="$(ps -p $$ -o comm= 2>/dev/null)" || return 1
	fi
	# On Alpine Linux the cut command above gives weird result, remove everything from the first blank space to the end
	proc_cmdline="${proc_cmdline%%[[:space:][:cntrl:]]*}"
	# Remove leading "-" added by macOS
	proc_cmdline="${proc_cmdline#-}"
	proc_cmdline="$(command -v "$proc_cmdline" 2>/dev/null)" || return 1
	proc_cmdline="$(realpath "$proc_cmdline" 2>/dev/null)" || return 1
	printf '%s\n' "$proc_cmdline"
)

# Detect if running on a problematic shell, and try to re-exec the script on a better shell
upgrade_to_better_shell() {
	current_shell="$(basename "$(real_proc_cmdline)" 2>/dev/null)"
	case "$current_shell" in
	# If running on dash, re-exec the script on bash if possible (for debian/ubuntu and derivatives)
	# If mksh, re-exec on anything available (mksh performs Field Splitting inconsistently between Parameter Expansion and Command Substitution)
	# If zsh, re-exec on anything available (zsh's sh compatibility mode is woefully incompatible, Field Splitting is unusable when IFS is changed)
	dash | mksh | zsh)
		if [ "$current_shell" != bash ] && command -v bash >/dev/null; then
			log_debug "${current_shell} detected, upgrading to bash"
			exec bash --posix "$0" "$@"
		elif [ "$current_shell" != busybox ] && command -v busybox >/dev/null; then
			log_debug "${current_shell} detected, upgrading to busybox"
			exec busybox "$0" "$@"
		elif [ "$current_shell" != dash ] && command -v dash >/dev/null; then
			log_debug "${current_shell} detected, upgrading to dash"
			exec dash "$0" "$@"
		fi
		;;
	esac
}

# Substitute every instance of character in text with replacement string
# This function uses only shell builtins and has no external dependencies (f.e. on sed)
# This is slower than using sed on a big input, but faster on many invocations with small inputs
substitute_character_builtin() (
	set -f # Disable globbing (aka pathname expansion)
	IFS="$1"
	trailing_match=
	case "$3" in *"$1") [ "$ZSH_VERSION" ] || trailing_match="$2" ;; esac
	last_field=
	first=1
	for field in $3; do
		[ "$first" ] || printf '%s%s' "$last_field" "$2"
		last_field="$field"
		first=
	done
	printf '%s%s' "$last_field" "$trailing_match"
)

# Escape text for use in a shell script single-quoted string (shell builtin version)
escape_single_quotes_builtin() { substitute_character_builtin \' "'\\''" "$1"; }

# Wrap all arguments in single-quotes and concatenate them separated by spaces
quote_for_eval() (
	for arg in "$@"; do
		printf "'%s' " "$(escape_single_quotes_builtin "$arg")"
	done
)

# Evaluate command in a sub-shell, abort on error
run() {
	log_info "$@"
	__dsm__eval_cmd="$(quote_for_eval "$@")"
	log_trace "dot-slash-make: [run] __dsm__eval_cmd=$__dsm__eval_cmd"
	(eval "$__dsm__eval_cmd") || abort "${0}: [target: ${__target}] Error ${?}"
}

# Evaluate command in a sub-shell, ignore returned status code
run_() {
	log_info "$@"
	__dsm__eval_cmd="$(quote_for_eval "$@")"
	log_trace "dot-slash-make: [run_] __dsm__eval_cmd=$__dsm__eval_cmd"
	(eval "$__dsm__eval_cmd") || log_warn "${0}: [target: ${__target}] Error ${?} (ignored)"
}

# Validate if text is appropriate for a shell variable name
validate_var_name() {
	case "$1" in
	*[!_a-zA-Z0-9]*) return 1 ;;
	[!_a-zA-Z]*) return 1 ;;
	esac
}

# Check if the given name was provided as an argument in the CLI
__dsm__is_in_cli_parameters_list() (
	log_trace "dot-slash-make: [__dsm__is_in_cli_parameters_list] var_name='${1}' __dsm__cli_parameters_list='${__dsm__cli_parameters_list}'"
	for arg in $(list_from "$__dsm__cli_parameters_list"); do
		[ "$1" = "$arg" ] && return 0
	done
	return 1
)

# Use indirection to dynamically set a variable from argument NAME=VALUE
__dsm__set_variable_cli_override() {
	__dsm__var_name="${2%%=*}"
	__dsm__var_value="${2#*=}"
	if validate_var_name "$__dsm__var_name"; then
		if [ "$1" ] && __dsm__is_in_cli_parameters_list "$__dsm__var_name"; then
			log_debug "dot-slash-make: [${1}] '$__dsm__var_name' overridden by command line argument"
			return
		fi
		eval "${__dsm__var_name}='$(escape_single_quotes_builtin "$__dsm__var_value")'"
		[ "$1" ] || __dsm__cli_parameters_list="${__dsm__cli_parameters_list}${__dsm__var_name} "
		eval "log_debug \"dot-slash-make: [${1:-__dsm__set_variable_cli_override}] ${__dsm__var_name}=\$${__dsm__var_name}\""
	else
		abort "${0}:${1:+" [$1]"} Invalid parameter name '${__dsm__var_name}'"
	fi
}

# Set variable from argument NAME=VALUE, only if it was not overridden by an argument on the CLI
param() { __dsm__set_variable_cli_override param "$@"; }

# Turn arguments into a list of items separated by IFS
list() { [ "$#" != 0 ] && printf '%s' "$*" && [ ! "$ZSH_VERSION" ] && printf '%s' "${IFS%"${IFS#?}"}"; }

# $(list_from string [separator]): Turn string into a list splitting at each occurrence of separator
# If separator isn't provided the default value of IFS is used (space|tab|line-feed)
list_from() (
	set -f # Disable globbing
	str="$1"
	[ "$ZSH_VERSION" ] && case "$1" in *["$2"]) str="${1%?}" ;; esac
	old_ifs="$IFS"
	IFS="${2:-"$(printf ' \t\n')"}"
	# shellcheck disable=SC2086
	IFS="$old_ifs" list $str
)

# Use pattern to format each subsequent argument, return a list separated by IFS
fmt() {
	__pattern="$1"
	shift
	# shellcheck disable=SC2059
	[ "$#" != 0 ] && list_from "$(printf "${__pattern}${IFS%"${IFS#?}"}" "$@")" "${IFS%"${IFS#?}"}"
}

# Perform tilde- and pathname-expansion (globbing) on arguments
# Similar behavior as the wildcard function in GNU Make
wildcard() (
	old_ifs="$IFS"
	IFS=
	buffer=
	for pattern in "$@"; do
		case "$pattern" in
		'~') pattern="$HOME" ;;
		'~'/*) pattern="${HOME}${pattern#'~'}" ;;
		esac
		set +f # Enable globbing
		for file in $pattern; do
			set -f
			# shellcheck disable=SC2086
			[ -e "$file" ] && buffer="$(IFS="$old_ifs" && list $buffer "$file")"
		done
	done
	printf '%s' "$buffer"
)

list_targets() { list_from "$__dsm__targets"; }

set -f # Disable globbing (aka pathname expansion)
case "$MAKE_DEBUG" in *shell*) ;; *) upgrade_to_better_shell "$@" ;; esac
__dsm__cli_parameters_list=
__dsm__targets=
__target=
for __dsm__arg in "$@"; do
	case "$__dsm__arg" in
	[_a-zA-Z]*=*) __dsm__set_variable_cli_override '' "$__dsm__arg" ;;
	-*) abort "${0}: invalid option '${__dsm__arg}'" ;;
	*) __dsm__targets="${__dsm__targets}${__dsm__arg} " ;;
	esac
done
[ "$__dsm__targets" ] || __dsm__targets=-
log_debug "dot-slash-make: targets list: '${__dsm__targets}'"
