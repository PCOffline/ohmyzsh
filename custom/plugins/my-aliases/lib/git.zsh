alias glod="git pull origin "$(git_develop_branch)""
alias glom="git pull origin "$(git_main_branch)""
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
alias ccurr="git_current_branch | tr -d '\n' | pbcopy"
alias gbdm='gbD $(get_merged_branches)'
alias gstash='gsta -S'
alias clc="last_commit | pbcopy"

function gcrename() {
    grename "$(git_current_branch)" $1
}

function last_commit() {
  git log -1 --oneline --pretty=format:"%h"
}

function get_branch() {
    local selected_prefix="* "
    local remotes_prefix="remotes/origin/"
    local raw_branch=$(gb -a | grep $1 -m 1 | xargs)
    local branch=${raw_branch#$selected_prefix}
    branch=${branch#$remotes_prefix}
    echo $branch
}

function get_merged_branches() {
    local current_branch=$(git_current_branch)
    local target_branch=${1:-$current_branch}

    # Find all merged branches, excluding the current branch and main/master branches
    git branch --merged "$target_branch" |
    grep -v "^\*" |
    grep -v "$target_branch$" |
    grep -v "master$" |
    grep -v "main$" |
    sed 's/^[ \t]*/  /'
}

function gsws() {
    gsw $(get_branch $@)
}

function gbDs() {
    gbD $(get_branch $@)
}

function cbs() {
    get_branch $@ | tr -d '\n' | pbcopy
}

function gtag() {
    git tag -d $1
    git push origin :$1
    git tag $1
    git push origin $1
}

function gdn() {
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
