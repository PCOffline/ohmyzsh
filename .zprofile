# Re-sourced by ~/.zshrc for non-login shells; guard keeps it idempotent.
[[ -n "$_ZPROFILE_SOURCED" ]] && return
export _ZPROFILE_SOURCED=1

# ── Auto-dedupe path/fpath ──────────────────────────────────────────────────
typeset -gU path fpath

# ── OS-specific setup ───────────────────────────────────────────────────────
if [[ -n "$_OS_IS_MACOS" ]]; then
  export HOMEBREW_PREFIX="/opt/homebrew"
  export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
  export HOMEBREW_REPOSITORY="/opt/homebrew"

  fpath=(/opt/homebrew/share/zsh/site-functions(N) $fpath)
  path=(
    $HOME/.local/bin
    /opt/homebrew/bin
    /opt/homebrew/sbin
    $path
  )

  case ":${INFOPATH-}:" in
    *:/opt/homebrew/share/info:*) ;;
    *) export INFOPATH="/opt/homebrew/share/info:${INFOPATH+:$INFOPATH}" ;;
  esac
fi

if [[ -n "$_OS_IS_LINUX" ]]; then
  if [[ -d /home/linuxbrew/.linuxbrew ]]; then
    export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
    export HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar"
    export HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX/Homebrew"
    fpath=($HOMEBREW_PREFIX/share/zsh/site-functions(N) $fpath)
    path=($HOMEBREW_PREFIX/bin $HOMEBREW_PREFIX/sbin $path)
  fi

  fpath=(
    /usr/share/zsh/vendor-completions(N)
    /usr/share/zsh/site-functions(N)
    $fpath
  )

  path=(
    $HOME/.local/bin
    $HOME/.cargo/bin(N)
    /snap/bin(N)
    $path
  )
fi

# ── Editor & tooling ────────────────────────────────────────────────────────
export EDITOR='zed'

# ── pnpm ────────────────────────────────────────────────────────────────────
if [[ -n "$_OS_IS_MACOS" ]]; then
  export PNPM_HOME="$HOME/Library/pnpm"
else
  export PNPM_HOME="$HOME/.local/share/pnpm"
fi
[[ -d "$PNPM_HOME" ]] && path=($PNPM_HOME $path)

# ── GPG_TTY ─────────────────────────────────────────────────────────────────
[[ -n "$TTY" ]] && export GPG_TTY="$TTY"
