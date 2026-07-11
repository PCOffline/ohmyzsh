#!/usr/bin/env zsh
emulate -L zsh
setopt pipe_fail

readonly PLUGIN_LIB=/home/tester/plugin/lib
readonly ASKPASS=/tmp/askpass.sh
readonly GPG_PASSPHRASE_FILE=$HOME/.gpg-pass

typeset -g PASS=0 FAIL=0
typeset -ga FAIL_MSGS

_pass() { PASS=$((PASS+1)); printf '  \033[32mPASS\033[0m  %s\n' "$1"; }
_fail() { FAIL=$((FAIL+1)); FAIL_MSGS+=("$1"); printf '  \033[31mFAIL\033[0m  %s\n' "$1"; }

assert_eq()       { [[ "$1" == "$2"   ]] && _pass "$3" || _fail "$3 (expected: $2, got: $1)"; }
assert_contains() { [[ "$1" == *"$2"* ]] && _pass "$3" || _fail "$3 (missing: $2)"; }
refute_contains() { [[ "$1" != *"$2"* ]] && _pass "$3" || _fail "$3 (unexpected: $2)"; }
assert_file()     { [[ -f "$1"        ]] && _pass "$2" || _fail "$2 (missing file: $1)"; }

section() { printf '\n── %s ──\n' "$1"; }
indent()  { sed 's/^/    | /'; }

setup_ssh_askpass() {
  # OpenSSH 8.4+ honors SSH_ASKPASS_REQUIRE=force even without a controlling
  # tty, provided DISPLAY is set. Ubuntu 24.04 ships OpenSSH 9.6.
  cat > "$ASKPASS" <<'ASK'
#!/bin/sh
exec echo ""
ASK
  chmod +x "$ASKPASS"
  export SSH_ASKPASS="$ASKPASS"
  export SSH_ASKPASS_REQUIRE=force
  export DISPLAY=:99
}

setup_gpg_loopback() {
  # Pre-configure gpg to use loopback pinentry with an empty passphrase from
  # a file, so `gpg --batch --generate-key` runs headlessly.
  mkdir -p ~/.gnupg
  chmod 700 ~/.gnupg
  print -r -- "allow-loopback-pinentry"              >  ~/.gnupg/gpg-agent.conf
  print -r -- "pinentry-mode loopback"               >  ~/.gnupg/gpg.conf
  print -r -- "passphrase-file $GPG_PASSPHRASE_FILE" >> ~/.gnupg/gpg.conf
  : > "$GPG_PASSPHRASE_FILE"
  gpgconf --kill gpg-agent 2>/dev/null || true
}

section "utility.zsh helpers on bare Ubuntu"

source "$PLUGIN_LIB/utility.zsh"

print -rn -- "test-payload" | _clipboard_copy 2>/dev/null
assert_eq "$?" "1" "_clipboard_copy returns non-zero when no tool installed"

_open_url http://example.com >/dev/null 2>&1
assert_eq "$?" "1" "_open_url returns non-zero when no opener installed"

section "gen_git_ssh on Ubuntu"

source "$PLUGIN_LIB/project.zsh"
setup_ssh_askpass

ssh_out=$(gen_git_ssh --email test@example.com </dev/null 2>&1)
ssh_status=$?
print -r -- "$ssh_out" | indent

assert_eq "$ssh_status" "0"                            "exits 0"
assert_file ~/.ssh/id_ed25519                          "private key created"
assert_file ~/.ssh/id_ed25519.pub                      "public key created"

ssh_config=$(<~/.ssh/config)
assert_contains "$ssh_config" "Host github.com"        "ssh config has Host github.com"
assert_contains "$ssh_config" "IdentityFile"           "ssh config has IdentityFile"
assert_contains "$ssh_config" "AddKeysToAgent yes"     "ssh config has AddKeysToAgent"
refute_contains "$ssh_config" "UseKeychain"            "ssh config does not include macOS UseKeychain"

assert_contains "$ssh_out" "Could not copy to clipboard" "reports clipboard-copy fallback"
assert_contains "$ssh_out" "ssh-ed25519"                 "prints public key to stdout on fallback"
refute_contains "$ssh_out" "apple-use-keychain"          "does not invoke --apple-use-keychain"
refute_contains "$ssh_out" "command not found"           "no missing-command errors"

section "gen_git_gpg on Ubuntu (batch mode)"

setup_gpg_loopback

gpg_out=$(gen_git_gpg --email gpgtest@example.com --name "GPG Tester" \
                     --type ed25519 --expire 0 </dev/null 2>&1)
gpg_status=$?
print -r -- "$gpg_out" | indent

assert_eq "$gpg_status" "0"                             "exits 0"
assert_contains "$gpg_out" "Key ID:"                    "prints Key ID"
assert_contains "$gpg_out" "Could not copy to clipboard" "reports clipboard-copy fallback"
assert_contains "$gpg_out" "BEGIN PGP PUBLIC KEY BLOCK" "prints ASCII-armored public key on fallback"
assert_contains "$gpg_out" "Added GPG_TTY to ~/.zshrc"  "updates ~/.zshrc with GPG_TTY"
refute_contains "$gpg_out" "brew"                       "does not invoke brew"
refute_contains "$gpg_out" "pinentry-mac"               "does not configure pinentry-mac"
refute_contains "$gpg_out" "command not found"          "no missing-command errors"

assert_contains "$(<~/.zshrc)" "GPG_TTY" "~/.zshrc contains GPG_TTY export"
assert_contains "$(gpg --list-secret-keys --keyid-format=long 2>/dev/null)" "gpgtest@example.com" "generated key visible in keyring"

section "git.zsh uses cross-platform helpers"

git_zsh=$(<"$PLUGIN_LIB/git.zsh")
refute_contains "$git_zsh" "pbcopy"          "git.zsh no longer references pbcopy"
assert_contains "$git_zsh" "_clipboard_copy" "git.zsh uses _clipboard_copy"

printf '\n════════════════════════════════════════════════════════════\n'
printf '  Passed: %d   Failed: %d\n' "$PASS" "$FAIL"
printf '════════════════════════════════════════════════════════════\n'

if (( FAIL > 0 )); then
  printf '\nFailing checks:\n'
  for m in "${FAIL_MSGS[@]}"; do printf '  - %s\n' "$m"; done
  exit 1
fi
