alias cd="z"
alias nug="npm update -g"
alias c="clear"
alias ncui="npm-check-updates --format group --interactive"
alias upciu="npx update-browserslist-db@latest"

# Watch utility
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

# Format only staged files
function p() {
    local staged=$(git staged)

    if [[ "$staged" == "" ]]; then
        return 1
    fi

    local filtered=$(git staged | grep -E '\.([jt]s|[jt]sx)$' | sed 's|^|../|')
    yarn prettier --affected --write $filtered
}

# Format only files in the given folder
function sfmt () {
    dir=$1

    if [[ $dir == "" ]]; then
        dir="."
    fi

    yarn prettier --write $dir
}
