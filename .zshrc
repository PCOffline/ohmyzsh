# Non-login shells skip .zprofile; re-source it here (guarded to stay idempotent).
[[ -z "$_ZPROFILE_SOURCED" && -r "${ZDOTDIR:-$HOME}/.zprofile" ]] && source "${ZDOTDIR:-$HOME}/.zprofile"

export ZSH="$HOME/ohmyzsh"

ZSH_THEME="pi"
HYPHEN_INSENSITIVE="true"
ENABLE_CORRECTION="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"
HIST_STAMPS="dd/mm/yyyy"
zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 13

MY_ALIASES_DISABLED=()
MY_ALIASES_AUTO_DETECT=true

# Skip the synchronous audit; done daily in the background below.
ZSH_DISABLE_COMPFIX=true

# Cached completions must be on fpath before compinit runs.
: ${ZSH_CACHE_DIR:=$ZSH/cache}
fpath=($ZSH_CACHE_DIR/completions(N) $fpath)

plugins=(
    aliases
    alias-hints
    git
    jsontools
    magic-enter
    my-aliases
    rust
    z
    zsh-defer
)
[[ -n "$_OS_IS_MACOS" ]] && plugins+=(macos)
[[ -n "$_OS_IS_LINUX" ]] && plugins+=(ubuntu)

source $ZSH/oh-my-zsh.sh

typeset -gU path fpath

# Loaded after the first prompt.
zsh-defer source ${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
zsh-defer source ${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ── mise ────────────────────────────────────────────────────────────────────
if (( $+commands[mise] )); then
  _mise_activate="$ZSH_CACHE_DIR/mise-activate.zsh"
  if [[ ! -s "$_mise_activate" || "$commands[mise]" -nt "$_mise_activate" ]]; then
    mkdir -p "${_mise_activate:h}"
    mise activate zsh > "$_mise_activate" 2>/dev/null
  fi
  zsh-defer source "$_mise_activate"

  _mise_dst="$ZSH_CACHE_DIR/completions/_mise"
  if [[ ! -s "$_mise_dst" || "$commands[mise]" -nt "$_mise_dst" ]]; then
    mkdir -p "${_mise_dst:h}"
    mise completion zsh > "$_mise_dst" 2>/dev/null &!
  fi
  unset _mise_activate _mise_dst
fi

# ── saml2aws ────────────────────────────────────────────────────────────────
if (( $+commands[saml2aws] )); then
  _saml2aws_dst="$ZSH_CACHE_DIR/completions/_saml2aws"
  if [[ ! -s "$_saml2aws_dst" || "$commands[saml2aws]" -nt "$_saml2aws_dst" ]]; then
    mkdir -p "${_saml2aws_dst:h}"
    saml2aws --completion-script-zsh > "$_saml2aws_dst" 2>/dev/null &!
  fi
  unset _saml2aws_dst
fi

# ── docker (also shadows Docker Desktop's flaky vendor _docker symlink) ─────
if (( $+commands[docker] )); then
  _docker_dst="$ZSH_CACHE_DIR/completions/_docker"
  if [[ ! -s "$_docker_dst" || "$commands[docker]" -nt "$_docker_dst" ]]; then
    mkdir -p "${_docker_dst:h}"
    docker completion zsh > "$_docker_dst" 2>/dev/null &!
  fi
  unset _docker_dst
fi

if [[ -n "$DEVOPS_REPO_PATH" ]]; then
  alias saml="source $DEVOPS_REPO_PATH/saml/saml.sh"
  alias pssh="python $DEVOPS_REPO_PATH/ssm/aws_ec2_connect.py"
fi

# ── Daily fpath security audit ──────────────────────────────────────────────
{
  emulate -L zsh
  stamp="${ZSH_CACHE_DIR:-$HOME/.cache}/.last-compaudit"
  zmodload zsh/datetime
  last=0
  [[ -f $stamp ]] && { zmodload -F zsh/stat b:zstat && zstat -A last +mtime $stamp; }
  if (( EPOCHSECONDS - last > 86400 )); then
    if compaudit &>/dev/null; then
      mkdir -p "${stamp:h}" && : > $stamp
    else
      print -u2 -- "[compaudit] insecure fpath dirs — run 'compaudit' to list"
    fi
  fi
} &!

# ── WSL Windows executables ─────────────────────────────────────────────────
# Added after OMZ so startup never scans /mnt/c during OMZ's command probes.
# Extend via $WSL_WIN_PATHS.
if [[ -n "$_OS_IS_WSL" ]]; then
  path+=(
    /mnt/c/Windows/System32(N)
    /mnt/c/Windows(N)
    /mnt/c/Windows/System32/WindowsPowerShell/v1.0(N)
    /mnt/c/Program\ Files/PowerShell/7*(N)
    /mnt/c/Users/*/AppData/Local/Programs/Zed*/bin(N)
    /mnt/c/Users/*/AppData/Local/Programs/Microsoft\ VS\ Code/bin(N)
  )
  [[ -n "$WSL_WIN_PATHS" ]] && path+=( "${(@s.:.)WSL_WIN_PATHS}" )
fi
