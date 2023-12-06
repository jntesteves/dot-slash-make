# SPDX-License-Identifier: Unlicense
# v0.1.0-pre
# shellcheck shell=sh
#
# This file is part of dot-slash-make https://codeberg.org/jntesteves/dot-slash-make
# Do NOT make changes to this file, your commands go in the ./make file
#
log_error() { printf 'ERROR %s\n' "$*" >&2; }
log_info() { printf '%s\n' "$*"; }
log_debug() { [ "$BUILD_DEBUG" ] && printf 'DEBUG %s\n' "$*"; }
abort() {
    log_error "$*"
    exit 1
}

# Escape text for use in a shell script single-quoted string (shell builtin version)
# This function uses only shell builtins and has no external dependencies (f.e. on sed)
# This is slower than using sed on big inputs, but faster on many calls with small inputs
escape_single_quotes() (
    arguments="$*"
    final_quote=
    case "$arguments" in
        *\') final_quote="'\\''" ;;
    esac
    set -f # Disable globbing. This ensures that the word-splitting is safe
    old_ifs=$IFS
    IFS=\'
    # shellcheck disable=2086
    set -- $arguments # Create arguments list splitting at each occurrence of IFS
    IFS=$old_ifs
    set +f # Re-enable globbing
    i=0
    arg_count="$#"
    for field in "$@"; do
        i=$((i + 1))
        if [ "$i" -eq "$arg_count" ]; then
            printf '%s%s' "$field" "$final_quote"
        else
            printf "%s'\\\\''" "$field"
        fi
    done
)

# Wrap all arguments in single-quotes and concatenate them
__quote_eval_cmd() (
    escaped_text=
    for arg in "$@"; do
        escaped_text="${escaped_text} '$(escape_single_quotes "$arg")'"
    done
    printf '%s\n' "$escaped_text"
)

# Evaluate command in a sub-shell, abort on error
run() {
    log_info "$*"
    __eval_cmd="$(__quote_eval_cmd "$@")"
    log_debug "dot-slash-make: run() __eval_cmd=$__eval_cmd"
    (eval "$__eval_cmd") || abort 'dot-slash-make: Command failed, aborting'
}

# Evaluate command in a sub-shell, ignore returned status code
run_() {
    log_info "$*"
    __eval_cmd="$(__quote_eval_cmd "$@")"
    log_debug "dot-slash-make: run_() __eval_cmd=$__eval_cmd"
    (eval "$__eval_cmd") || log_info 'dot-slash-make: Command failed, ignoring failure status'
}

# Validate if text is appropriate for a shell variable name
validate_var_name() {
    case "$1" in
        *[!_a-zA-Z0-9]*) return 1 ;;
        [!_a-zA-Z]*) return 1 ;;
    esac
}

# Use indirection to dynamically set a variable from argument NAME=VALUE
set_variable() {
    __fn_arguments="$*"
    __var_name="${__fn_arguments%%=*}"
    __var_value="${__fn_arguments#*=}"
    if validate_var_name "$__var_name"; then
        eval "$__var_name='$(escape_single_quotes "$__var_value")'"
        eval "log_debug \"dot-slash-make: set_variable() ${__var_name}=\$${__var_name}\""
    else
        abort "dot-slash-make: Invalid variable name $__var_name"
    fi
}

__targets=
for __arg in "$@"; do
    case "$__arg" in
        [_a-zA-Z]*=*) set_variable "$__arg" ;;
        -*) abort "dot-slash-make: Unrecognized option '${__arg}'" ;;
        *) __targets="${__targets}
${__arg}" ;;
    esac
done

# shellcheck disable=2086
set -- $__targets
[ "$1" ] || set -- ''
log_debug "dot-slash-make: targets list: '$*'"
