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
function opr() {
  open "https://bitbucket.org/buildots-ai/buildots/pull-requests/new?source=$(git_current_branch)&t=1"
}

function trns() {
  if [[ $# -lt 2 ]]; then
    echo "Usage: trns <key> <value>"
    echo "  Appends a new translation entry to translations.csv"
    return 1
  fi

  local key="$1"
  local value="$2"

  if [[ -z "$key" ]]; then
    echo "Error: key cannot be empty"
    return 1
  fi

  if [[ -z "$value" ]]; then
    echo "Error: value cannot be empty"
    return 1
  fi

  local frontend_path
  frontend_path="$(z -e frontend 2>/dev/null)"
  if [[ $? -ne 0 || -z "$frontend_path" ]]; then
    echo "Error: could not resolve 'frontend' directory via z"
    return 1
  fi

  local path="${frontend_path}/../translations.csv"
  if [[ ! -f "$path" ]]; then
    echo "Error: translations file not found at: $path"
    return 1
  fi

  if [[ ! -w "$path" ]]; then
    echo "Error: translations file is not writable: $path"
    return 1
  fi

  echo "$key,$value,,,,,,," >> "$path"
  if [[ $? -eq 0 ]]; then
    echo "Added translation: $key -> $value"
  else
    echo "Error: failed to write to $path"
    return 1
  fi
}

function gen_git_ssh() {
  local email="" host="" key_file=""
  local -a email_arg host_arg output_arg help_flag

  # Parse flags
  zparseopts -D -E -F -- \
    e:=email_arg -email:=email_arg \
    H:=host_arg -host:=host_arg \
    o:=output_arg -output:=output_arg \
    h=help_flag -help=help_flag \
    || { echo "Usage: gen_git_ssh --email <email> [--host <host>] [--output <path>]"; return 1; }

  # Show help
  if [[ -n "$help_flag" ]]; then
    echo "Usage: gen_git_ssh --email <email> [--host <host>] [--output <path>]"
    echo ""
    echo "Generate an SSH key and configure it for Git."
    echo ""
    echo "Options:"
    echo "  -e, --email   Email for the SSH key (required)"
    echo "  -H, --host    SSH host (default: github.com)"
    echo "  -o, --output  Key file path (default: ~/.ssh/id_ed25519)"
    echo "  -h, --help    Show this help message"
    return 0
  fi

  # Extract values from parsed flags
  email="${email_arg[-1]}"
  host="${host_arg[-1]:-github.com}"
  key_file="${output_arg[-1]:-$HOME/.ssh/id_ed25519}"

  # Validate required arguments
  if [[ -z "$email" ]]; then
    echo "Usage: gen_git_ssh --email <email> [--host <host>] [--output <path>]"
    echo "  -e, --email   Email for the SSH key (required)"
    echo "  -H, --host    SSH host (default: github.com)"
    echo "  -o, --output  Key file path (default: ~/.ssh/id_ed25519)"
    echo "  -h, --help    Show this help message"
    return 1
  fi

  # Generate the SSH key
  ssh-keygen -t ed25519 -C "$email" -f "$key_file"

  # Verify key generation succeeded
  if [[ ! -f "$key_file" ]] || [[ ! -f "${key_file}.pub" ]]; then
    echo "Error: Key generation failed"
    return 1
  fi

  eval "$(ssh-agent -s)"

  # Create ~/.ssh/config if it doesn't exist
  if [[ ! -f ~/.ssh/config ]]; then
    touch ~/.ssh/config
  fi

  # Add host to ~/.ssh/config if not already present
  if ! grep -q "^Host $host$" ~/.ssh/config; then
    echo "Host $host" >> ~/.ssh/config
    echo "  IdentityFile $key_file" >> ~/.ssh/config
    echo "  AddKeysToAgent yes" >> ~/.ssh/config
    # Only add UseKeychain if supported
    if ssh -o UseKeychain=yes -o BatchMode=yes localhost 2>&1 | grep -qv "Bad configuration option"; then
      echo "  UseKeychain yes" >> ~/.ssh/config
    fi
  fi

  # Add key to ssh-agent
  if ! ssh-add --apple-use-keychain "$key_file" 2>/dev/null; then
    /usr/bin/ssh-add --apple-use-keychain "$key_file"
  fi

  pbcopy < "${key_file}.pub"
  echo "Copied public key to clipboard"
}

function gen_git_gpg() {
  local email="" name="" key_type="" apply_scope="" expire=""
  local -a email_arg name_arg type_arg apply_arg expire_arg help_flag

  # Parse flags
  zparseopts -D -E -F -- \
    e:=email_arg -email:=email_arg \
    n:=name_arg -name:=name_arg \
    t:=type_arg -type:=type_arg \
    a:=apply_arg -apply:=apply_arg \
    x:=expire_arg -expire:=expire_arg \
    h=help_flag -help=help_flag \
    || { echo "Usage: gen_git_gpg [--email <email>] [--name <name>] [--type <type>] [--expire <date>] [--apply <global|local>]"; return 1; }

  # Show help
  if [[ -n "$help_flag" ]]; then
    echo "Usage: gen_git_gpg [--email <email>] [--name <name>] [--type <type>] [--expire <date>] [--apply <global|local>]"
    echo ""
    echo "Generate a GPG key and configure it for Git commit signing."
    echo "If --email and --name are both provided, runs in batch mode."
    echo "Otherwise, runs GPG interactively."
    echo ""
    echo "Options:"
    echo "  -e, --email   Email for the GPG key"
    echo "  -n, --name    Real name for the GPG key"
    echo "  -t, --type    Key type: ed25519 (default) or rsa4096"
    echo "  -x, --expire  Expiration: 0 (never, default), 1y, 6m, 30d, or YYYY-MM-DD"
    echo "  -a, --apply   Configure Git: 'global' (all repos) or 'local' (current repo)"
    echo "  -h, --help    Show this help message"
    echo ""
    echo "Also configures macOS GPG environment (GPG_TTY, pinentry-mac)."
    return 0
  fi

  # Extract values from parsed flags
  email="${email_arg[-1]}"
  name="${name_arg[-1]}"
  key_type="${type_arg[-1]:-ed25519}"
  apply_scope="${apply_arg[-1]}"
  expire="${expire_arg[-1]:-0}"

  # Check gpg is installed
  if ! command -v gpg &>/dev/null; then
    echo "Error: gpg is not installed"
    return 1
  fi

  # Validate key type
  if [[ -n "${type_arg[-1]}" && "$key_type" != "ed25519" && "$key_type" != "rsa4096" ]]; then
    echo "Error: --type must be 'ed25519' or 'rsa4096'"
    return 1
  fi

  # Validate apply scope
  if [[ -n "$apply_scope" && "$apply_scope" != "global" && "$apply_scope" != "local" ]]; then
    echo "Error: --apply must be 'global' or 'local'"
    return 1
  fi

  # Check --apply local requires being in a git repo (early check)
  if [[ "$apply_scope" == "local" ]] && ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Error: --apply local requires being inside a Git repository"
    return 1
  fi

  # macOS GPG configuration: Add GPG_TTY to .zshrc if not present
  if ! grep -q "GPG_TTY" ~/.zshrc 2>/dev/null; then
    echo 'export GPG_TTY=$(tty)' >> ~/.zshrc
    echo "Added GPG_TTY to ~/.zshrc"
  fi

  # Check if pinentry-mac is installed, offer to install if not
  if ! command -v pinentry-mac &>/dev/null; then
    if read -q "?pinentry-mac not found. Install it for GUI pin entry? (y/n) "; then
      echo
      brew install pinentry-mac
    else
      echo
    fi
  fi

  # Configure gpg-agent to use pinentry-mac if available
  if command -v pinentry-mac &>/dev/null; then
    local pinentry_path="$(brew --prefix)/bin/pinentry-mac"

    mkdir -p ~/.gnupg
    if ! grep -q "pinentry-program" ~/.gnupg/gpg-agent.conf 2>/dev/null; then
      echo "pinentry-program $pinentry_path" >> ~/.gnupg/gpg-agent.conf
      echo "Configured pinentry-mac in gpg-agent.conf"
    fi

    # Restart gpg-agent to apply changes
    killall gpg-agent 2>/dev/null || true
  fi

  # Generate GPG key
  local gen_status=0
  if [[ -n "$email" && -n "$name" ]]; then
    # Batch mode
    if [[ "$key_type" == "rsa4096" ]]; then
      gpg --batch --generate-key <<EOF
Key-Type: RSA
Key-Length: 4096
Key-Usage: sign
Name-Real: $name
Name-Email: $email
Expire-Date: $expire
%commit
EOF
      gen_status=$?
    else
      gpg --batch --generate-key <<EOF
Key-Type: eddsa
Key-Curve: ed25519
Key-Usage: sign
Name-Real: $name
Name-Email: $email
Expire-Date: $expire
%commit
EOF
      gen_status=$?
    fi
  else
    # Interactive mode
    gpg --full-generate-key
    gen_status=$?
  fi

  if [[ $gen_status -ne 0 ]]; then
    echo "Error: GPG key generation failed"
    return 1
  fi

  # Extract key ID (most recently created key)
  local key_id
  key_id=$(gpg --list-secret-keys --keyid-format=long 2>/dev/null | grep -E "^\s+[A-F0-9]{16,}" | tail -n1 | awk '{print $1}')

  if [[ -z "$key_id" ]]; then
    echo "Error: Could not find the generated key"
    return 1
  fi

  # Copy public key to clipboard
  gpg --armor --export "$key_id" | pbcopy
  echo "Copied public key to clipboard"
  echo "Key ID: $key_id"

  # Handle --apply flag
  if [[ "$apply_scope" == "global" ]]; then
    git config --global user.signingkey "$key_id"
    git config --global commit.gpgsign true
    echo "Configured Git globally to sign commits with this key"
  elif [[ "$apply_scope" == "local" ]]; then
    git config user.signingkey "$key_id"
    git config commit.gpgsign true
    echo "Configured current repository to sign commits with this key"
  else
    echo ""
    echo "To configure Git to use this key in a specific repo:"
    echo "  git config user.signingkey $key_id"
    echo "  git config commit.gpgsign true"
  fi
}
