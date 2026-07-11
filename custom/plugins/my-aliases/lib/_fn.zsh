# ── Declarative Function Helpers ─────────────────────────────────────────────
# Minimal, readable validation for shell functions.
#
# Usage pattern:
#   function my_func() {
#       @doc "Description of what this does" "<required-arg> [optional-arg]"
#       @needs 1 "$@" || return
#       @git || return
#       ...
#   }

# ─── Colors (respects NO_COLOR) ─────────────────────────────────────────────
if [[ -z "$NO_COLOR" ]]; then
  _FN_RED='\033[0;31m'
  _FN_YELLOW='\033[0;33m'
  _FN_CYAN='\033[0;36m'
  _FN_DIM='\033[2m'
  _FN_RESET='\033[0m'
else
  _FN_RED='' _FN_YELLOW='' _FN_CYAN='' _FN_DIM='' _FN_RESET=''
fi

# ─── Internal ───────────────────────────────────────────────────────────────
_FN_DOC_DESC=""
_FN_DOC_ARGS=""

_fn_err() {
  echo "${_FN_RED}error${_FN_RESET}: $1" >&2
}

_fn_warn() {
  echo "${_FN_YELLOW}warning${_FN_RESET}: $1" >&2
}

# ─── @doc ────────────────────────────────────────────────────────────────────
# Declare function description and argument spec (displayed on --help).
#
#   @doc "Short description" "<arg1> [arg2]"
#   @doc "Short description"                     # no args
#
@doc() {
  _FN_DOC_DESC="$1"
  _FN_DOC_ARGS="${2:-}"
}

# ─── @needs ──────────────────────────────────────────────────────────────────
# Validate minimum arg count and handle --help/-h.
# Must be called after @doc. Uses the stored description/args for help output.
#
#   @needs 1 "$@" || return
#   @needs 0 "$@" || return    # no required args, but still supports --help
#
@needs() {
  local min=$1; shift
  local fname="${funcstack[2]}"

  # Check for --help / -h
  local arg
  for arg in "$@"; do
    if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
      echo "Usage: ${fname}${_FN_DOC_ARGS:+ ${_FN_DOC_ARGS}}"
      echo ""
      echo "  ${_FN_DOC_DESC}"
      return 1
    fi
  done

  # Validate arg count
  if (( $# < min )); then
    echo "Usage: ${fname}${_FN_DOC_ARGS:+ ${_FN_DOC_ARGS}}" >&2
    _fn_err "expected at least ${min} argument(s), got $#"
    return 1
  fi

  return 0
}

# ─── @git ────────────────────────────────────────────────────────────────────
# Assert the current directory is inside a git repository.
#
#   @git || return
#
@git() {
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    _fn_err "not inside a git repository"
    return 1
  fi
}

# ─── @cmd ────────────────────────────────────────────────────────────────────
# Assert that a command exists on PATH.
#
#   @cmd "fzf" || return
#
@cmd() {
  if ! command -v "$1" &>/dev/null; then
    _fn_err "required command not found: ${_FN_CYAN}$1${_FN_RESET}"
    return 1
  fi
}

# ─── @file ───────────────────────────────────────────────────────────────────
# Assert that a file exists.
#
#   @file "$path" || return
#
@file() {
  if [[ ! -f "$1" ]]; then
    _fn_err "file not found: $1"
    return 1
  fi
}

# ─── @dir ────────────────────────────────────────────────────────────────────
# Assert that a directory exists.
#
#   @dir "$path" || return
#
@dir() {
  if [[ ! -d "$1" ]]; then
    _fn_err "directory not found: $1"
    return 1
  fi
}

# ─── @var ────────────────────────────────────────────────────────────────────
# Assert that a variable is set and non-empty.
#
#   @var "KUBECTL_NAMESPACE" "$KUBECTL_NAMESPACE" || return
#
@var() {
  if [[ -z "$2" ]]; then
    _fn_err "required variable not set: ${_FN_CYAN}\$${1}${_FN_RESET}"
    return 1
  fi
}

# ─── @oneof ──────────────────────────────────────────────────────────────────
# Assert that a value is one of a set of allowed values.
#
#   @oneof "mode" "$mode" "local" "global" || return
#
@oneof() {
  local label=$1 value=$2; shift 2
  local opt
  for opt in "$@"; do
    [[ "$value" == "$opt" ]] && return 0
  done
  _fn_err "${label} must be one of: ${(j:, :)@} (got '${value}')"
  return 1
}
