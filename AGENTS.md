# AGENTS.md

Personal Ansible playbook that configures one person's macOS and Fedora
workstation (install packages, write app dotfiles/config). It is a flat
playbook, **not** an Ansible role. There is no application code to build.

## Layout

- `ansible/main.yml` — single play, `hosts: all`. Dispatches by facts:
  - vars by `ansible_system`: `vars/Darwin.yml` (macOS),
    `vars/Linux.yml` (Fedora)
  - tasks by `ansible_distribution`: `tasks/MacOSX.yml`, `tasks/Fedora.yml`
  - shared: `vars/common.yml`, `tasks/common.yml`, `handlers/handlers.yml`
- `ansible/files/` — templates (`.j2`) and dotfiles copied to the workstation.
  Files under `ansible/files/home/myusername/.config/` (incl. `opencode.json`,
  VS Code `settings.json`) are **deployed artifacts**, not repo config — do not
  treat them as settings for this repo.
- `ansible/vars/secrets.yml.vault` — ansible-vault encrypted. Decrypts with
  `ansible/vault-my_workstation.password` (gitignored; CI writes a dummy one).
- Wrapper scripts at repo root run the playbook; `scripts/` and
  `kickstart_file/` are Fedora ISO bootstrap helpers.

## Running the playbook

Run from inside `ansible/` (scripts `cd` there). A
`vault-my_workstation.password` file must exist first.

- macOS, full local run: `./run_ansible_my_workstation-local-mac.sh`
- Fedora/Linux local run: `./run_ansible_my_workstation-local.sh`
- Remote host: `./run_ansible_my_workstation.sh` (edit `DESTINATION_IP`)
- `MY_PASSWORD` must be filled into the wrapper scripts before use.

## Tags (important for partial runs)

Tasks are gated by tags. CI skips
`data,interactive,secrets,skip_test` (plus `skip_idempotence_test` on the
second pass). Other notable tags: `mc`, `printer`, `secrets`, `data`.

- `data` = large rsync of `~` and copying private files from local disk.
- `secrets` = vault-backed credentials (postfix, KeePass, rclone, gh).
- `skip_test` / `skip_idempotence_test` = exclude from CI / idempotence check.

Example focused run (macOS, Midnight Commander config only, no data):

```bash
ansible-playbook --skip-tags data --tags mc \
  --connection=local -i "127.0.0.1," main.yml
```

## CI and how to reproduce it

Workflows run on push to **non-`main`** branches and on PRs — nothing runs on
`main` except release-please. To get green CI, match these locally:

- `macos.yml` / `fedora.yml`: run the playbook, then run it **again** as an
  idempotence test. The second run must report `changed=0 ... failed=0` or CI
  fails. New tasks must be idempotent or carry `changed_when: false` /
  `skip_idempotence_test`. `fedora.yml` push trigger is currently commented
  out (manual dispatch only).
- `mega-linter.yml`: MegaLinter `documentation` flavor. Config in
  `.mega-linter.yml`. It extracts `bash`/`shell`/`sh` blocks from changed
  `*.md` and shellchecks them, so fenced shell in Markdown must be valid.
- `commit-check.yml`: validates commit + branch names on PRs.

## Conventions specific to this repo

- **`keep-sorted` blocks**: many lists are wrapped in
  `# keep-sorted start` / `# keep-sorted end` (some with `newline_separated=yes`
  or `block=yes`). When adding entries (packages, casks, extensions, ini
  options), insert them in sorted order within the block; CI enforces it.
- **ansible-lint**: config `ansible/.ansible-lint.yml`. `package-latest` and
  several `yaml[...]` rules are skipped — installing "latest" packages is
  intentional, don't "fix" it. Run `ansible-lint` from repo root after editing
  playbook YAML.
- Shell scripts: `shellcheck` (excludes `SC2317`) and `shfmt` with
  `--case-indent --indent 2 --space-redirects`.
- Markdown: linted by `rumdl` (config `.rumdl.toml`), wrapped at 80 chars;
  links checked by `lychee` (`lychee.toml`, `.lycheeignore`).
- Two-space indent everywhere; no tabs.

## Commits / branches / PRs

- Conventional Commits; subject ≤ 72 chars, lower case, imperative, no trailing
  period (enforced by commit-check).
- Conventional Branch names: `feature/`, `bugfix/`, `hotfix/`, `release/`,
  `chore/` + lowercase-hyphen description.
- Open PRs as **draft**; title must be a conventional-commit string
  (semantic-pull-request check). Releases are automated by release-please —
  do not hand-edit `CHANGELOG.md`.
