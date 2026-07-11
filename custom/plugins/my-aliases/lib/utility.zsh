alias cd="z"
alias nug="npm update -g"
alias c="clear"
alias ncui="npm-check-updates --format group --interactive"
alias upciu="npx update-browserslist-db@latest"

function _clipboard_copy() {
  if [[ "$OSTYPE" == darwin* ]] && command -v pbcopy &>/dev/null; then
    pbcopy
  elif [[ -n "$WAYLAND_DISPLAY" ]] && command -v wl-copy &>/dev/null; then
    wl-copy
  elif command -v xclip &>/dev/null; then
    xclip -selection clipboard
  elif command -v xsel &>/dev/null; then
    xsel --clipboard --input
  elif command -v clip.exe &>/dev/null; then
    clip.exe
  else
    return 1
  fi
}

function _open_url() {
  if [[ "$OSTYPE" == darwin* ]] && command -v open &>/dev/null; then
    open "$@"
  elif command -v xdg-open &>/dev/null; then
    xdg-open "$@"
  elif command -v wslview &>/dev/null; then
    wslview "$@"
  elif command -v explorer.exe &>/dev/null; then
    explorer.exe "$@"
  else
    echo "Error: no supported 'open' command found (install xdg-utils on Linux)" >&2
    return 1
  fi
}

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

alias fal="alias | grep"
