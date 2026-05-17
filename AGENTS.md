# Repo Guide for AI Agents

Ansible repo that configures the maintainer's personal workstations
(macOS + Fedora). YAML, Bash, Jinja2. Generic conventions live in
`~/.config/opencode/AGENTS.md`; only repo-specific guidance is below.

## Layout

- `ansible/main.yml` — single playbook entrypoint. Includes
  `vars/<system>.yml` (`Darwin`/`Linux`) then runs
  `tasks/<distribution>.yml` (`MacOSX.yml`/`Fedora.yml`) then
  `tasks/common.yml`.
- `ansible/tasks/` — three large monolithic task files
  (`common.yml` ~790 lines, `Fedora.yml` ~1080, `MacOSX.yml` ~880).
  No roles. Add new tasks inline in the matching OS file or
  `common.yml`.
- `ansible/vars/` — `common.yml` (shared), `Darwin.yml` (macOS),
  `Linux.yml` (Fedora), `secrets.yml.vault` (vault-encrypted).
- `ansible/files/{Users,home,etc}/` — files copied to target;
  `Users/` is macOS, `home/` is Linux. Source path under
  `myusername/` is templated at runtime.
- `ansible/handlers/handlers.yml` — all handlers.
- `ansible/ansible.cfg` — sets
  `vault_password_file = vault-my_workstation.password`
  (gitignored, must exist before running).
- `scripts/`, `kickstart_file/` — Fedora ISO rebuild bits, not
  part of the playbook run.

## Running

All `run_ansible_my_workstation*.sh` wrappers `cd ansible` first.

```bash
# Local macOS run (matches the maintainer's flow)
./run_ansible_my_workstation-local-mac.sh   # edit MY_PASSWORD first

# Plain local run (no vault password needed if file is present)
./run_ansible_my_workstation-local.sh

# CI-equivalent run (no secrets, no interactive, no large data)
ansible-playbook --skip-tags data,interactive,secrets,skip_test \
  --connection=local -i "127.0.0.1," ansible/main.yml

# Idempotence check: re-run with the same skip-tags and expect
# `changed=0.*failed=0` (CI greps for this exact pattern).

# Single feature subset
ansible-playbook --tags mc --connection=local -i "127.0.0.1," ansible/main.yml
```

Before any local run: create `ansible/vault-my_workstation.password`
(plain text, one line). CI writes `"test_password"` into it.

## Tags (used to gate CI and selective runs)

- `secrets` — uses vault-encrypted vars. Skipped in CI.
- `data` — large data ops (backups, restores). Skipped in CI.
- `interactive` — needs user input. Skipped in CI.
- `skip_test` — never run in CI for any reason.
- `skip_idempotence_test` — runs first CI pass but skipped on the
  second idempotence pass (use for tasks that legitimately change
  every run).
- Feature tags (`mc`, `printer`, …) — for ad-hoc selective runs.

Tag every new task that fits these buckets, or CI will fail
idempotence or break.

## Ansible conventions (enforced)

- **FQCN only**: `ansible.builtin.copy`, `community.general.ini_file`,
  etc. Short names will fail `ansible-lint`.
- Collections pinned in `ansible/requirements.yml`:
  `ansible.posix`, `community.general`. Install with
  `ansible-galaxy install -r ansible/requirements.yml`.
- **File modes are symbolic**: `mode: u=rw,g=r,o=r`, never `"0644"`.
- Every task needs a descriptive `name:`.
- `ansible-lint` config at `ansible/.ansible-lint.yml` skips
  `package-latest`, `yaml[comments]`, `yaml[document-start]`,
  `yaml[line-length]` — do not rely on line-length wrapping in YAML.
- Lint command: `ansible-lint -c ansible/.ansible-lint.yml ansible/`

## `keep-sorted` blocks

Keep-sorted `start` / `end` comment markers appear in YAML
lists, var blocks, and `ansible.cfg`. Insertions must stay
alphabetically sorted within the markers; do not remove the markers.

## CI specifics

- `.github/workflows/macos.yml` runs on every push (not main) that
  touches `ansible/{files,handlers,main.yml,tasks/{MacOSX,common}.yml,vars/{Darwin,common}.yml}`
  or the workflow itself. Runs the playbook twice (apply +
  idempotence) and fails if the second run reports any changes.
- `.github/workflows/fedora.yml` is `workflow_dispatch` only
  (push trigger commented out) — uses Vagrant + VirtualBox on
  `macos-15`.
- Full local lint pass mirroring CI: `mega-linter-runner --flavor documentation`
  (requires Docker).

## Shell wrappers

The `run_ansible_my_workstation*.sh` scripts use `set -eux` and
`cd ansible || exit`. Keep them small; real logic belongs in
playbooks. Lint with
`shellcheck --exclude=SC2317` and
`shfmt --case-indent --indent 2 --space-redirects`.

## Things not to do

- Don't add roles or restructure into multiple plays — current
  design is intentionally one play, three task files.
- Don't commit `ansible/vault-my_workstation.password` (gitignored).
- Don't use octal file modes or short module names — lint will
  fail.
- Don't add tasks that change on every run without
  `skip_idempotence_test` — CI macos job will fail.
