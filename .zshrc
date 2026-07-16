# Environment/PATH setup lives in ~/.zprofile so that non-interactive shells
# (scripts, `zsh -c`, editor tasks) see the same environment.

# Path to your oh-my-zsh installation.
export ZSH="$HOME/ohmyzsh"

ZSH_THEME="pi"

HYPHEN_INSENSITIVE="true"
zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 13
ENABLE_CORRECTION="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"
HIST_STAMPS="dd/mm/yyyy"

# Custom aliases config
MY_ALIASES_DISABLED=()
MY_ALIASES_AUTO_DETECT=true

# Skip OMZ's synchronous compaudit. A background
# safety net further down runs `compaudit` once per day and warns if
# any fpath dir has become group/world-writable.
ZSH_DISABLE_COMPFIX=true

plugins=(
    aliases
    alias-hints
    git
    jsontools
    macos
    magic-enter
    my-aliases
    rust
    z
    zsh-defer
)

source $ZSH/oh-my-zsh.sh

# Force PATH dedup
path=($path); fpath=($fpath)

# ── Deferred heavy plugins (load after prompt is drawn) ───────────────────────
zsh-defer source ${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
zsh-defer source ${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ── defer mise activation ───────────────────────────────────────────────────
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

# ── saml2aws completion ─────────────────────────────────────────────────────
if (( $+commands[saml2aws] )); then
  _saml2aws_dst="$ZSH_CACHE_DIR/completions/_saml2aws"
  if [[ ! -s "$_saml2aws_dst" || "$commands[saml2aws]" -nt "$_saml2aws_dst" ]]; then
    mkdir -p "${_saml2aws_dst:h}"
    saml2aws --completion-script-zsh > "$_saml2aws_dst" 2>/dev/null &|
  fi
  unset _saml2aws_dst
fi

# ── User aliases ────────────────────────────────────────────────────────────
alias saml="source $DEVOPS_REPO_PATH/saml/saml.sh"
alias pssh="python $DEVOPS_REPO_PATH/ssm/aws_ec2_connect.py"

# ── Daily compaudit ─────────────────────────────────────────────────────────
# Since ZSH_DISABLE_COMPFIX=true above skips OMZ's synchronous audit, this
# runs `compaudit` once per day in the background and prints a warning if any
# fpath directory becomes group/world-writable.
{
  emulate -L zsh
  stamp="${ZSH_CACHE_DIR:-$HOME/.cache}/.last-compaudit"
  zmodload zsh/datetime
  last=0
  if [[ -f $stamp ]]; then
    zmodload -F zsh/stat b:zstat && zstat -A last +mtime $stamp
  fi
  if (( EPOCHSECONDS - last > 86400 )); then
    if compaudit &>/dev/null; then
      mkdir -p "${stamp:h}" && : > $stamp
    else
      print -u2 -- "[compaudit] insecure fpath dirs found — run 'compaudit' to see, 'compaudit | xargs chmod g-w,o-w' to fix"
    fi
  fi
} &!
