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

# Open a new PR from the current branch
function pr() {
  open "https://bitbucket.org/buildots-ai/buildots/pull-requests/new?source=$(git_current_branch)&t=1"
}
