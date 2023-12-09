# SPDX-License-Identifier: Unlicense
# v0.1.0-pre
# shellcheck shell=sh
#
# This file is part of dot-slash-make https://codeberg.org/jntesteves/dot-slash-make
# Do NOT make changes to this file, your commands go in the ./make file
#
log_error() { printf 'ERROR %s\n' "$*" >&2; }
log_warn() { printf 'WARN %s\n' "$*" >&2; }
log_info() { printf '%s\n' "$*"; }
log_debug() { :; }
log_trace() { :; }
abort() {
    log_error "$*"
    exit 1
}
[ "$BUILD_DEBUG" ] && log_debug() { printf 'DEBUG %s\n' "$*"; }
case "$BUILD_DEBUG" in *trace*) log_trace() { printf 'TRACE %s\n' "$*"; } ;; esac

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

# Detect if running on dash, and if so, re-run the script on bash if possible
upgrade_from_dash_to_bash() {
    if [ "$(basename "$(real_proc_cmdline)" 2>/dev/null)" = dash ] && command -v bash >/dev/null; then
        log_debug 'dot-slash-make: dash detected, upgrading to bash'
        exec bash --posix "$0" "$@"
    fi
}

# Substitute every instance of character in text with replacement text
# This function uses only shell builtins and has no external dependencies (f.e. on sed)
# This is slower than using sed on big inputs, but faster on many invocations with small inputs
substitute_character_builtin() (
    char="$1"
    replacement_text="$2"
    shift 2
    text="$*"
    trailing_match=
    case "$text" in
        *"$char") [ "$ZSH_VERSION" ] || trailing_match="$replacement_text" ;;
    esac
    old_ifs="$IFS"
    IFS="$char"
    set -f # Disable globbing. This ensures word-splitting is safe
    # shellcheck disable=2086
    set -- $text # Create arguments list splitting at each occurrence of IFS
    set +f       # Re-enable globbing
    IFS="$old_ifs"
    i=0
    arg_count="$#"
    for field in "$@"; do
        i=$((i + 1))
        if [ "$i" -eq "$arg_count" ]; then
            printf '%s%s' "$field" "$trailing_match"
        else
            printf '%s%s' "$field" "$replacement_text"
        fi
    done
)

# Escape text for use in a shell script single-quoted string (shell builtin version)
escape_single_quotes_builtin() (
    substitute_character_builtin \' "'\\''" "$*"
)

# Wrap all arguments in single-quotes and concatenate them
__quote_eval_cmd() (
    escaped_text=
    for arg in "$@"; do
        escaped_text="${escaped_text} '$(escape_single_quotes_builtin "$arg")'"
    done
    printf '%s\n' "$escaped_text"
)

# Evaluate command in a sub-shell, abort on error
run() {
    log_info "$*"
    __eval_cmd="$(__quote_eval_cmd "$@")"
    log_trace "dot-slash-make: run() __eval_cmd=$__eval_cmd"
    (eval "$__eval_cmd") || abort 'dot-slash-make: Command failed, aborting'
}

# Evaluate command in a sub-shell, ignore returned status code
run_() {
    log_info "$*"
    __eval_cmd="$(__quote_eval_cmd "$@")"
    log_trace "dot-slash-make: run_() __eval_cmd=$__eval_cmd"
    (eval "$__eval_cmd") || log_info 'dot-slash-make: Command failed, ignoring failure status'
}

# Validate if text is appropriate for a shell variable name
validate_var_name() {
    case "$1" in
        *[!_a-zA-Z0-9]*) return 1 ;;
        [!_a-zA-Z]*) return 1 ;;
    esac
}

# Check if the given name was provided as an argument in the CLI
__is_in_cli_parameters_list() (
    var_name="$1"
    log_trace "dot-slash-make: __is_in_cli_parameters_list() var_name='${var_name}' __cli_parameters_list='${__cli_parameters_list}'"
    for arg in $__cli_parameters_list; do
        log_trace "dot-slash-make: __is_in_cli_parameters_list() loop arg='${arg}'"
        [ "$var_name" = "$arg" ] && return 0
    done
    return 1
)

# Use indirection to dynamically set a variable from argument NAME=VALUE
__set_variable_cli_override() {
    __fn_param=
    [ "$1" = .param ] && __fn_param=' param()' && shift
    __fn_arguments="$*"
    __var_name="${__fn_arguments%%=*}"
    __var_value="${__fn_arguments#*=}"
    if validate_var_name "$__var_name"; then
        if [ "$__fn_param" ] && __is_in_cli_parameters_list "$__var_name"; then
            log_debug "dot-slash-make: param() '$__var_name' found in CLI parameters list, ignoring"
            return
        fi
        eval "$__var_name='$(escape_single_quotes_builtin "$__var_value")'"
        [ "$__fn_param" ] || __cli_parameters_list="${__cli_parameters_list}${__var_name} "
        eval "log_debug \"dot-slash-make: __set_variable_cli_override() ${__var_name}=\$${__var_name}\""
    else
        abort "dot-slash-make:$__fn_param Invalid variable name '$__var_name'"
    fi
}

# Set variable from argument NAME=VALUE, only if it was not overridden by an argument on the CLI
param() {
    __set_variable_cli_override .param "$@"
}

upgrade_from_dash_to_bash "$@"
__cli_parameters_list=
__targets=
for __arg in "$@"; do
    case "$__arg" in
        [_a-zA-Z]*=*) __set_variable_cli_override "$__arg" ;;
        -*) abort "dot-slash-make: Unrecognized option '${__arg}'" ;;
        *) __targets="${__targets}${__arg} " ;;
    esac
done
[ "$__targets" ] || __targets=-
log_debug "dot-slash-make: targets list: '${__targets}'"
