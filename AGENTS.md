# AI Agent Guidelines

## Overview

Ansible repository that configures personal workstations (macOS and
Fedora Linux). Primary languages: YAML (Ansible), Bash, Jinja2.

## Build / Lint / Test Commands

```bash
# Install Ansible Galaxy dependencies
ansible-galaxy install -r ansible/requirements.yml

# Run playbook locally (macOS)
cd ansible || exit
ansible-playbook --connection=local -i "127.0.0.1," main.yml

# Run playbook skipping certain tags (CI mode)
ansible-playbook --skip-tags data,interactive,secrets,skip_test \
  --connection=local -i "127.0.0.1," main.yml

# Run a single tagged subset of tasks
ansible-playbook --tags mc --connection=local -i "127.0.0.1," main.yml

# Lint Ansible files
ansible-lint -c ansible/.ansible-lint.yml ansible/

# Lint shell scripts
shellcheck --exclude=SC2317 run_ansible_my_workstation*.sh
shfmt --case-indent --indent 2 --space-redirects -d run_ansible_my_workstation*.sh

# Lint Markdown
rumdl .

# Check links
lychee --config lychee.toml .

# Validate GitHub Actions workflows
actionlint

# Full CI linting (requires Docker)
mega-linter-runner --flavor documentation
```

## Ansible Conventions

- **FQCN required**: Always use fully qualified collection names
  (e.g., `ansible.builtin.copy`, `community.general.ini_file`),
  never short names like `copy` or `file`
- **Collections**: `ansible.builtin`, `ansible.posix`,
  `community.general` (defined in `ansible/requirements.yml`)
- **Task naming**: Every task must have a descriptive `name:` field
- **File modes**: Use symbolic notation (`mode: u=rw,g=r,o=r`)
  not octal (`mode: "0644"`)
- **Become**: Use `become: true` in block-level when multiple tasks
  need root, or per-task when only one does
- **Tags**: Use tags for selective execution and test control:
  - `secrets` - tasks using vault-encrypted variables
  - `data` - tasks involving large data operations
  - `interactive` - tasks requiring user input
  - `skip_test` - tasks that should not run in CI
  - `skip_idempotence_test` - tasks that are not idempotent
  - Feature-specific tags: `mc`, `printer`, etc.
- **Variables**: Define in `ansible/vars/common.yml` (shared),
  `ansible/vars/Darwin.yml` (macOS), `ansible/vars/Linux.yml`
  (Fedora)
- **OS-specific tasks**: `ansible/tasks/MacOSX.yml` (macOS),
  `ansible/tasks/Fedora.yml` (Fedora), `ansible/tasks/common.yml`
  (shared)
- **ansible-lint skips**: `package-latest`, `yaml[comments]`,
  `yaml[document-start]`, `yaml[line-length]`

## Sorted Lists

This repo uses `# keep-sorted start` / `# keep-sorted end` comments
to maintain alphabetical ordering in YAML lists, config blocks, and
variable definitions. Always preserve these markers and keep items
sorted alphabetically within them.

## Shell Scripts

- **Linting**: Must pass `shellcheck` (SC2317 excluded)
- **Formatting**: `shfmt --case-indent --indent 2 --space-redirects`
- **Variables**: Use uppercase with braces (`${MY_VARIABLE}`)
- **Indentation**: 2 spaces, no tabs

## Markdown Files

- Must pass `rumdl` checks (`CHANGELOG.md` excluded)
- Wrap lines at 72 characters
- Use proper heading hierarchy (no skipped levels)
- Include language identifiers in code fences
- Shell code blocks must also pass `shellcheck` and `shfmt`

## JSON Files

- Must pass `jsonlint --comments` validation
- `.devcontainer/devcontainer.json` is excluded from linting

## Link Checking

- `lychee` validates URLs (config in `lychee.toml`)
- Accepts status codes 200 and 429
- Excludes `CHANGELOG.md`, private IPs, template variables

## Security Scanning

- **Checkov**: IaC scanner (skips `CKV_GHA_7`)
- **DevSkim**: Pattern scanner (ignores DS162092, DS137138)
- **KICS**: Fails on HIGH severity only
- **Trivy**: HIGH/CRITICAL severity, ignores unfixed

## GitHub Actions

- Pin actions to full SHA commits, never tags
- Use minimal permissions (`permissions: read-all`)
- Validate changes with `actionlint`

## Version Control

### Commit Messages

Conventional commit format: `<type>: <description>`

- Types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`,
  `style`, `perf`, `ci`, `build`, `revert`
- Subject: imperative mood, lowercase, no period, max 72 chars
- Body: wrap at 72 chars, explain what and why
- Reference issues: `Fixes`, `Closes`, `Resolves`

```text
feat: add automated dependency updates

- Implement Dependabot configuration
- Configure weekly security updates

Resolves: #123
```

### Branching

Follow conventional branch format: `<type>/<description>`

- `feature/` or `feat/`, `bugfix/` or `fix/`, `hotfix/`,
  `release/`, `chore/`
- Lowercase, hyphens only, no consecutive/trailing hyphens

### Pull Requests

- Always create as **draft** initially
- Title must follow conventional commit format
- Include clear description and link related issues

## General Style

- **Indentation**: 2 spaces everywhere (YAML, shell, JSON)
- **No tabs**: Spaces only in all files
- **Formatting**: Consistent formatting across all file types
- **Atomic commits**: One logical change per commit
