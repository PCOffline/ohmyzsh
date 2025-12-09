# zsh Aliases
alias zshconfig="code ~/.zshrc"
alias zconfig="zshconfig"
alias ohmyzsh="code ~/ohmyzsh"
alias soz="source ~/.zshrc"

# Utility Aliases
alias cd="z"
alias nug="npm update -g"
alias c="clear"
alias ncui="npm-check-updates --format group --interactive"

# Kubernetes Aliases
alias kc="kubectl config use-context"
alias kd="kubectl describe"
alias kg="kubectl get"
alias kgp="kubectl get pods"
alias kgpw="watch 'kubectl get pods'"
alias kgpcl="kubectl get pods | grep CrashLoopBackOff"
alias kgs="kubectl get services"
alias kgn="kubectl get nodes"
alias kgm="kubectl get namespaces"
alias kl="kubectl logs -p"
alias kdp="kubectl delete pod"

function get_pod() {
    local keyword=$1
    local namespace=$2
    
    if [[ $keyword == "" ]]; then
        echo "No pod name provided"
        return 1
    fi
    
    if [[ $namespace == "" ]]; then
        namespace="eldar"
    fi
    
    echo $(kgp -n $namespace | grep "^$keyword" | awk '{print $1}')
}

function kgl() {
    local pod=$(get_pod $@)
    local namespace=$2
    
    if [[ $namespace == "" ]]; then
        namespace="eldar"
    fi
    
    kubectl logs $pod -n $namespace
}

function kdpa() {
    local namespace=$1
    
    if [[ $namespace == "" ]]; then
        namespace="eldar"
    fi
    
    local pod=$(kgp -n $namespace | grep "CrashLoopBackOff" | awk '{print $1}')
    kubectl delete pod $pod -n $namespace
}

function kdps() {
    local pod=$(get_pod $@)
    local namespace=$2
    
    if [[ $namespace == "" ]]; then
        namespace="eldar"
    fi
    
    kdp $pod -n $namespace
}

function kgenv() {
    local pod=$(get_pod $@)
    local namespace=$2
    
    echo $pod
    
    if [[ $namespace == "" ]]; then
        namespace="eldar"
    fi
    
    kubectl exec -it $pod -n $namespace -- env
}

function watch2() {
    IN=1
    case $1 in
        -n)
            IN=$2
            shift 2
        ;;
    esac
    printf '\033c' # clear
    CM="$*"
    LEFT="$(printf 'Every %.1f: %s' $IN $CM)"
    ((PAD = COLUMNS - ${#LEFT}))
    while :; do
        DT=$(date)
        local a=$(eval "$CM")
        printf '\033c'
        printf "$LEFT%${PAD}s\n" "$HOST $(date)"
        echo $a
        sleep $IN
    done
}

# Git Aliases
## Rename current branch
alias gpod="git pull origin "$(git_develop_branch)""
alias glom="git pull origin "$(git_main_branch)""
alias gpn="git prune"
alias gpu="gp -u origin $(current_branch)"
alias s="gsw -"
alias gde="gd ':!package-lock.json'"
alias grH="grh HEAD^"   # git reset HEAD^
alias gruH="gru HEAD^"  # git reset -- HEAD^
alias grhH="grhh HEAD^" # git reset --hard HEAD^
alias grkH="grhk HEAD^" # git reset --keep HEAD^
alias grsH="grhs HEAD^" # git reset --soft HEAD^
alias good="git bisect good"
alias bad="git bisect bad"
alias ccurr="current_branch | tr -d '\n' | pbcopy"
alias gbdm='gbD $(get_merged_branches)'

function gcrename() {
    grename "$(current_branch)" $1
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
    local current_branch=$(get_current_branch)
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

# Project Aliases
function yes() {
    if [ $# -eq 0 ] ; then
        yarn "start:devgrounds"
    else
        if [[ $1 =~ ^(dev0?)?([1-9])$ ]] ; then
            yarn "start:dev0${match[2]}"
            elif [[ $1 =~ ^(dev)?(1[1-5])$ ]] ; then
            yarn "start:dev${match[2]}"
        else
            echo "Error! $@"
        fi
    fi
}

alias ts="yarn typecheck"
alias pmo="yarn format"
alias tspmo="ts & pmo & wait"

function p() {
    local staged=$(git staged)
    
    if [[ "$staged" == "" ]]; then
        return 1
    fi
    
    local filtered=$(git staged | grep -E '\.([jt]s|[jt]sx)$' | sed 's|^|../|')
    yarn prettier --affected --write $filtered
}

function sfmt () {
    dir=$1
    
    if [[ $dir == "" ]]; then
        dir="."
    fi
    
    yarn prettier --write $dir
}

# Rust Aliases
alias rs="rustc"
alias cr="cargo run"
alias cb="cargo build"
alias ct="cargo test"
alias cbr="cargo build --release"
alias ctd="cargo test -- --nocapture"
alias cbrd="cargo build --release -- --nocapture"
alias crl="cargo clean"
alias cfv="cargo fmt --all -- --check"
alias trs="trunk serve"
alias trso="trunk serve --open"
