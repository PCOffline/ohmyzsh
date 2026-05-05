# Alias Hints Plugin
# Detects when you type a command that has a shorter alias and nudges you.
#
# HOW IT WORKS
#   1. Resolves alias chains in your typed command
#      (e.g. gr --verbose → git remote --verbose)
#   2. Checks custom rules registered via alias_hint_add — first match wins
#   3. Falls back to auto-detection: matches against every alias expansion
#      (also resolves chains in expansions, so grH → grh HEAD^ → git reset HEAD^)
#
# CONFIGURATION (set in .zshrc before loading oh-my-zsh):
#   ALIAS_HINTS_ENABLED=false       # Disable hints  (default: true)
#   ALIAS_HINTS_EXCLUDE=(ll cd)     # Aliases to never hint about
#
# CUSTOM RULES (call from any plugin or .zshrc loaded after alias-hints):
#   alias_hint_add <pattern> <suggestion> [message]
#     pattern     regex matched against the fully-resolved command
#     suggestion  what to display as the recommended alternative
#     message     optional context shown in parentheses

: ${ALIAS_HINTS_ENABLED:=true}
: ${ALIAS_HINTS_EXCLUDE:=()}

# ── Custom rules storage (ordered triplets: pattern, suggestion, message) ───
typeset -ga _alias_hint_rules=()

alias_hint_add() {
  _alias_hint_rules+=("$1" "$2" "${3:-}")
}

# ── First-word index + lazy expansion cache ─────────────────────────────────
# _alias_hint_by_cmd: resolved_first_word → "name1 name2 …" (space-separated)
# _alias_hint_cache:  alias_name → fully-resolved expansion (populated on demand)
typeset -gA _alias_hint_by_cmd=()
typeset -gA _alias_hint_cache=()
typeset -g  _alias_hint_cache_ready=""

alias_hint_rebuild() {
  _alias_hint_by_cmd=()
  _alias_hint_cache=()
  local name exp fw prev_fw
  local -i j

  for name exp in "${(@kv)aliases}"; do
    # Follow only the first-word chain to find the resolved first word.
    # This is cheap: just hash lookups on single words, no string concat.
    fw="${exp%% *}"
    prev_fw=""
    for (( j=0; j<10; j++ )); do
      [[ -z "${aliases[$fw]+x}" || "$fw" == "$name" || "$fw" == "$prev_fw" ]] && break
      prev_fw="$fw"
      fw="${aliases[$fw]%% *}"
    done
    _alias_hint_by_cmd[$fw]+="$name "
  done
  _alias_hint_cache_ready=1
}

# ── Resolve alias chains in a typed command ─────────────────────────────────
# Sets: _alias_hints_resolved  (fully-expanded command string)
#       _alias_hints_chain     (list of alias names that were expanded)
_alias_hints_resolve() {
  _alias_hints_resolved="$1"
  _alias_hints_chain=()
  local f rest prev_f=""
  local -i i

  for (( i=0; i<10; i++ )); do
    f="${_alias_hints_resolved%% *}"
    [[ -z "${aliases[$f]+x}" ]] && break
    [[ "$f" == "$prev_f" ]] && break
    _alias_hints_chain+=("$f")
    prev_f="$f"
    rest="${_alias_hints_resolved#"$f"}"
    _alias_hints_resolved="${aliases[$f]}${rest}"
  done
}

# ── preexec hook ────────────────────────────────────────────────────────────
_alias_hint_preexec() {
  [[ "$ALIAS_HINTS_ENABLED" != "true" ]] && return

  local typed="$1"
  [[ -z "$typed" ]] && return

  # Skip commands injected by magic-enter (empty-line Enter)
  if (( ${+functions[magic-enter]} )); then
    [[ "$typed" == "${MAGIC_ENTER_GIT_COMMAND}" ]] && return
    [[ "$typed" == "${MAGIC_ENTER_JJ_COMMAND}" ]] && return
    [[ "$typed" == "${MAGIC_ENTER_OTHER_COMMAND}" ]] && return
  fi

  # Build index on first use (all plugins have loaded by now)
  [[ -z "$_alias_hint_cache_ready" ]] && alias_hint_rebuild

  # Resolve the typed command
  _alias_hints_resolve "$typed"
  local resolved="$_alias_hints_resolved"
  local typed_cmd="${typed%% *}"

  # ── Phase 1: Custom rules (first match wins) ──────────────────────────
  local pat sug msg sug_cmd
  local -i idx
  for (( idx=1; idx<=${#_alias_hint_rules}; idx+=3 )); do
    pat="${_alias_hint_rules[$idx]}"
    sug="${_alias_hint_rules[$((idx+1))]}"
    msg="${_alias_hint_rules[$((idx+2))]}"
    sug_cmd="${sug%% *}"

    # Don't suggest what the user already typed / expanded through
    [[ "$sug_cmd" == "$typed_cmd" ]] && continue
    (( ${_alias_hints_chain[(Ie)$sug_cmd]} )) && continue
    (( ${ALIAS_HINTS_EXCLUDE[(Ie)$sug_cmd]} )) && continue

    if [[ "$resolved" =~ "^${pat}$" ]]; then
      if [[ -n "$msg" ]]; then
        printf '\e[33m💡 Alias tip:\e[0m Use \e[1m%s\e[0m instead  \e[2m(%s)\e[0m\n' \
          "$sug" "$msg" >&2
      else
        printf '\e[33m💡 Alias tip:\e[0m Use \e[1m%s\e[0m instead  \e[2m(%s → %s)\e[0m\n' \
          "$sug" "$sug_cmd" "${aliases[$sug_cmd]}" >&2
      fi
      return
    fi
  done

  # ── Phase 2: Auto-detection (longest resolved expansion wins) ─────────
  #    Only scan aliases indexed under the same first word, and resolve
  #    each candidate's full expansion lazily (cached across commands).
  local best="" best_resolved=""
  local -i best_len=0
  local first_resolved="${resolved%% *}"
  local name resolved_exp r f rest prev_f
  local -i i
  for name in ${(s: :)_alias_hint_by_cmd[$first_resolved]}; do
    # Lazy-resolve: only compute the full expansion the first time
    if [[ -z "${_alias_hint_cache[$name]+x}" ]]; then
      r="${aliases[$name]}"
      prev_f=""
      for (( i=0; i<10; i++ )); do
        f="${r%% *}"
        [[ -z "${aliases[$f]+x}" ]] && break
        [[ "$f" == "$prev_f" ]] && break
        prev_f="$f"
        rest="${r#"$f"}"
        r="${aliases[$f]}${rest}"
      done
      _alias_hint_cache[$name]="$r"
    fi
    resolved_exp="${_alias_hint_cache[$name]}"

    (( ${#resolved_exp} <= best_len )) && continue
    (( ${ALIAS_HINTS_EXCLUDE[(Ie)$name]} )) && continue
    (( ${_alias_hints_chain[(Ie)$name]} )) && continue

    if [[ "${resolved}" == "${resolved_exp}" || "${resolved}" == "${resolved_exp} "* ]]; then
      best="$name"
      best_len=${#resolved_exp}
      best_resolved="$resolved_exp"
    fi
  done

  if [[ -n "$best" ]]; then
    local remainder="${resolved#"${best_resolved}"}"
    local suggestion="${best}${remainder}"

    # Only suggest if it's actually shorter than what was typed
    (( ${#suggestion} >= ${#typed} )) && return

    printf '\e[33m💡 Alias tip:\e[0m Use \e[1m%s\e[0m instead  \e[2m(%s → %s)\e[0m\n' \
      "$suggestion" "$best" "${aliases[$best]}" >&2
  fi
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec _alias_hint_preexec
