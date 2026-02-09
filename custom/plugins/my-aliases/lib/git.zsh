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

function gcrename() {
    grename "$(git_current_branch)" $1
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
