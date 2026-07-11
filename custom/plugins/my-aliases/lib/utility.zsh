alias cd="z"
alias nug="npm update -g"
alias c="clear"
alias ncui="npm-check-updates --format group --interactive"
alias upciu="npx update-browserslist-db@latest"

function watch2() {
    @doc "Repeatedly run a command at a given interval" "[-n interval] <command>"
    @needs 1 "$@" || return

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

function p() {
    @doc "Format staged JS/TS files using Prettier"
    @needs 0 "$@" || return
    @git || return

    local staged=$(git staged)

    if [[ "$staged" == "" ]]; then
        return 1
    fi

    local filtered=$(git staged | grep -E '\.([jt]s|[jt]sx)$' | sed 's|^|../|')
    yarn prettier --affected --write $filtered
}

function sfmt() {
    @doc "Format files in a directory using Prettier" "[dir]"
    @needs 0 "$@" || return

    local dir=${1:-.}
    yarn prettier --write $dir
}

alias fal="alias | grep"

function validate_hash() {
    @doc "Validate a file's SHA-256 checksum against an expected hash" "<file> <expected_sha256>"
    @needs 2 "$@" || return

    local file=$1
    local hash=$2

    @file "$file" || return

    if [[ $(sha256sum "$file" | awk '{print $1}') != "$hash" ]]; then
        _fn_err "hash mismatch: $file"
        return 1
    fi

    return 0
}
