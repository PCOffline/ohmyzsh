# ── Homebrew (hardcoded — avoids subprocess fork on every shell start) ───────
export HOMEBREW_PREFIX="/opt/homebrew"
export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
export HOMEBREW_REPOSITORY="/opt/homebrew"

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export MANPATH="/opt/homebrew/share/man${MANPATH+:$MANPATH}:"
export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"

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

# zsh-autosuggestions & zsh-syntax-highlighting are deferred below for faster startup
plugins=(
    aliases
    alias-hints
    git
    jsontools
    macos
    magic-enter
    mise
    my-aliases
    rust
    z
    zsh-defer
)

source $ZSH/oh-my-zsh.sh

# ── Deferred heavy plugins (load after prompt is drawn) ─────────────────────
zsh-defer source ${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
zsh-defer source ${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ── User configuration ──────────────────────────────────────────────────────
export EDITOR='zed'
export KUBECTL_NAMESPACE='your_namespace'

# pnpm
export PNPM_HOME="~/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Pycode
export PYTHONPATH="~/projects/buildots/pycode:$PYTHONPATH"
export HDF5_DIR=/opt/homebrew/Cellar/hdf5/1.14.6/
export GPG_TTY=$(tty)
