# This file is NOT sourced by `zsh -c` subshells — anything scripts need should live here.

# ── Auto-dedupe path/fpath ──────────────────────────────────────────────────
typeset -gU path fpath

# ── OS-specific setup ───────────────────────────────────────────────────────
if [[ "$OSTYPE" == darwin* ]]; then
  export HOMEBREW_PREFIX="/opt/homebrew"
  export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
  export HOMEBREW_REPOSITORY="/opt/homebrew"

  # Prepend Homebrew's zsh completion dir
  fpath=(/opt/homebrew/share/zsh/site-functions $fpath)

  path=(
    $HOME/.local/bin
    /Library/Frameworks/Python.framework/Versions/3.9/bin
    /opt/homebrew/bin
    /opt/homebrew/sbin
    $path
  )

  case ":${INFOPATH-}:" in
    *:/opt/homebrew/share/info:*) ;;
    *) export INFOPATH="/opt/homebrew/share/info:${INFOPATH-}" ;;
  esac

elif [[ "$OSTYPE" == linux* ]]; then
  # Optional Linuxbrew — only prepend if the tree exists.
  if [[ -d /home/linuxbrew/.linuxbrew ]]; then
    export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
    export HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar"
    export HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX/Homebrew"
    fpath=($HOMEBREW_PREFIX/share/zsh/site-functions $fpath)
    path=($HOMEBREW_PREFIX/bin $HOMEBREW_PREFIX/sbin $path)
  fi

  # Apt/dpkg-installed completions
  fpath=(
    /usr/share/zsh/vendor-completions(N)
    /usr/share/zsh/site-functions(N)
    $fpath
  )

  # Common Linux user/system dirs.
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
if [[ "$OSTYPE" == darwin* ]]; then
  export PNPM_HOME="$HOME/Library/pnpm"
else
  export PNPM_HOME="$HOME/.local/share/pnpm"
fi
case ":${PATH}:" in
  *":$PNPM_HOME:"*) ;;
  *) path=($PNPM_HOME $path) ;;
esac

# ── GPG_TTY ─────────────────────────────────────────────────────────────────
[[ -n "$TTY" ]] && export GPG_TTY="$TTY"
