alias gpn="git prune"
alias s="gsw -"
alias gde="gd ':!package-lock.json'"
alias grH="grh HEAD^"   # git reset HEAD^
alias gruH="gru HEAD^"  # git reset -- HEAD^
alias grhH="grhh HEAD^" # git reset --hard HEAD^
alias grkH="grhk HEAD^" # git reset --keep HEAD^
alias grsH="grhs HEAD^" # git reset --soft HEAD^
alias good="git bisect good"
alias bad="git bisect bad"
alias ccurr="git_current_branch | tr -d '\n' | _clipboard_copy"
alias gstash='gsta -S'
alias clc="last_commit | _clipboard_copy"

function glod() {
  @doc "Pull from develop branch"
  @git || return

  git pull origin "$(git_develop_branch)" "$@";
}

function glom() {
  @doc "Pull from main branch"
  @git || return

  git pull origin "$(git_main_branch)" "$@";
}

function gbdm() {
  @doc "Delete merged branches"
  @git || return

  gbD $(get_merged_branches);
}

function gcrename() {
    @doc "Rename the current branch" "<new-name>"
    @needs 1 "$@" || return
    @git || return

    grename "$(git_current_branch)" $1
}

function last_commit() {
    @doc "Print the short hash of the last commit"
    @needs 0 "$@" || return
    @git || return

    git log -1 --oneline --pretty=format:"%h"
}

function get_branch() {
    @doc "Find the first branch matching a pattern (local or remote)" "<pattern>"
    @needs 1 "$@" || return
    @git || return

    local selected_prefix="* "
    local remotes_prefix="remotes/origin/"
    local raw_branch=$(gb -a | grep $1 -m 1 | xargs)
    local branch=${raw_branch#$selected_prefix}
    branch=${branch#$remotes_prefix}
    echo $branch
}

function get_branch_interactive() {
    @doc "Interactively select a branch using fzf" "[-r|-l] [query]"
    @needs 0 "$@" || return
    @git || return
    @cmd "fzf" || return

    local branch_flag="-a"
    while getopts "rl" opt; do
        case $opt in
            r) branch_flag="-r" ;;
            l) branch_flag="" ;;
        esac
    done
    shift $((OPTIND - 1))

    local selected_prefix="* "
    local remotes_prefix="remotes/origin/"
    local raw_branch=$(gb $branch_flag | sed 's/^[ \t]*//' | fzf --query="$1" --select-1 --exit-0)
    local branch=${raw_branch#$selected_prefix}
    branch=${branch#$remotes_prefix}
    echo $branch
}

function get_merged_branches() {
    @doc "List branches merged into target (defaults to current branch)" "[branch]"
    @needs 0 "$@" || return
    @git || return

    local current_branch=$(git_current_branch)
    local target_branch=${1:-$current_branch}

    git branch --merged "$target_branch" |
    grep -v "^\*" |
    grep -v "$target_branch$" |
    grep -v "master$" |
    grep -v "main$" |
    sed 's/^[ \t]*/  /'
}

function get_gone_branches() {
    @doc "List local branches whose remote upstream has been deleted"
    @needs 0 "$@" || return
    @git || return

    git branch -vv |
    grep -v "^\*" |
    grep -v "$(git_main_branch)$" |
    grep -v "$(git_develop_branch)$" |
    grep ': gone]' |
    awk '{print $1}' |
    sed 's/^[ \t]*/  /'
}

function gsws() {
    @doc "Switch to the first branch matching a pattern" "<pattern>"
    @needs 1 "$@" || return
    @git || return

    gsw $(get_branch $@)
}

function gbDs() {
    @doc "Force-delete the first branch matching a pattern" "<pattern>"
    @needs 1 "$@" || return
    @git || return

    gbD $(get_branch $@)
}

function cbs() {
    @doc "Copy the first matching branch name to clipboard" "<pattern>"
    @needs 1 "$@" || return
    @git || return

    get_branch $@ | tr -d '\n' | _clipboard_copy
}

function gtag() {
    @doc "Recreate a tag locally and on origin (delete + create + push)" "<tag-name>"
    @needs 1 "$@" || return
    @git || return

    git tag -d $1
    git push origin :$1
    git tag $1
    git push origin $1
}

function gdn() {
    @doc "Git diff excluding lock files" "[diff-args...]"
    @needs 0 "$@" || return
    @git || return

    gdnolock $@ ":!**/*-lock.json" ":!**/*.lock"
}

# ── Alias Hints ─────────────────────────────────────────────────────────────
# Custom rules for patterns that auto-detection can't catch.
# Rules are checked in order — first match wins.
if (( ${+functions[alias_hint_add]} )); then
  # Prefer git switch over git checkout
  alias_hint_add "git checkout -[bB] .+" "gswc" "prefer 'git switch --create' over 'git checkout -b'"
  alias_hint_add "git checkout .+" "gsw" "prefer 'git switch' over 'git checkout'"

  # Dynamic branch aliases (prefer over hardcoded branch names)
  alias_hint_add "git switch (dev|devel|develop|development)" "gswd" "auto-detects develop branch"
  alias_hint_add "git switch (main|master)" "gswm" "auto-detects main branch"
  alias_hint_add "git (pull|merge) origin (dev|devel|develop|development)" "glod" "auto-detects develop branch"
  alias_hint_add "git (pull|merge) origin (main|master)" "glom" "auto-detects main branch"

  # Partial branch matching (catch-all — must come after specific rules)
  alias_hint_add "git switch [^-].+" "gsws <partial>" "finds branches by partial name"
  alias_hint_add "git branch -[dD] [^-].+" "gbDs <partial>" "finds branches by partial name"

  # Flag equivalences
  alias_hint_add "git remote (-v|--verbose)" "grv"
fi
