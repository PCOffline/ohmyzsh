# my-aliases · tests

End-to-end tests that verify the plugin works on Ubuntu (Linux) without any
of the macOS-only tools available — no `pbcopy`, no `open`, no `brew`, no
`pinentry-mac`, no `--apple-use-keychain`, no `UseKeychain`.

## Requirements

- Docker (native Linux daemon, or Docker Desktop with WSL integration
  — `run.sh` falls back to `docker.exe` if the native client can't reach a
  daemon).

## Run

From the plugin root:

```sh
bash tests/run.sh
```

The script:

1. Builds `ubuntu:24.04` with only `zsh`, `git`, `gnupg`, and
   `openssh-client` installed.
2. Copies the plugin's `lib/` into the container.
3. Runs `test.zsh` and prints a pass/fail summary.
4. Deletes the built image on exit.

Exit code is `0` iff every check passed.

## Layout

```
tests/
├── Dockerfile   # Ubuntu env; build context is the plugin root
├── README.md    # this file
├── run.sh       # single-command entry point
└── test.zsh     # assertions, run inside the container
```

## What it covers

| # | Area | Verifies |
|---|------|----------|
| 1 | `utility.zsh` helpers | `_clipboard_copy` and `_open_url` return non-zero when no OS tool is installed, so callers can fall back cleanly. |
| 2 | `gen_git_ssh` end-to-end | Keys are generated in `~/.ssh/`; `~/.ssh/config` gets `Host`, `IdentityFile`, `AddKeysToAgent` but **not** `UseKeychain`; `ssh-add` is invoked without `--apple-use-keychain`; when clipboard copy fails, the public key is printed to stdout. |
| 3 | `gen_git_gpg` end-to-end | ed25519 key generated and visible in the keyring; `GPG_TTY` appended to `~/.zshrc`; no `brew` invocation and no `pinentry-mac` configuration; when clipboard copy fails, the ASCII-armored public key is printed to stdout. |
| 4 | `git.zsh` rewrites | Source no longer references `pbcopy` and does reference `_clipboard_copy`. |

## Test-environment shims

Docker containers don't provide a controlling terminal, and both flows
prompt for a passphrase via one. `test.zsh` shims the environment without
touching the code under test:

- **SSH** — sets `SSH_ASKPASS_REQUIRE=force` + a stub askpass script so
  `ssh-keygen` and `ssh-add` bypass the tty prompt. Requires OpenSSH 8.4+
  (Ubuntu 24.04 ships 9.6).
- **GPG** — pre-writes `~/.gnupg/gpg.conf` with `pinentry-mode loopback`
  and `passphrase-file` pointing at an empty file, so
  `gpg --batch --generate-key` runs headlessly with an empty passphrase.

Real users invoking the functions from a real terminal never hit either
prompt-bypass path.
