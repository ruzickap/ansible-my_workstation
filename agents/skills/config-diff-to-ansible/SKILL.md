---
name: config-diff-to-ansible
description: >-
  Find only the config options a user changed from the application's
  defaults and turn that diff into Ansible tasks for this playbook. Works
  by backing up the current config, letting the app regenerate its
  defaults, diffing, then restoring the original config and app state.
  Use whenever the user wants to "capture my settings", "ansibilize" an
  app's config, find non-default options, or add an app's dotfile/ini/
  plist/JSON settings to the playbook - even if they don't say "diff".
---

# Config diff to Ansible

Goal: encode only the user's **non-default** settings, so the playbook
stays small and keeps working when upstream defaults change. Copying a
whole config file pins every default forever - avoid that.

## Workflow

Work in a scratch dir, e.g. `${TMPDIR}/config-diff/<app>/`.

1. **Locate the config.** Find the file(s) the app reads (docs,
   `~/.config/<app>/`, `~/Library/Preferences/<bundle-id>.plist`,
   `~/Library/Application Support/<app>/`). Confirm with the user if
   unsure. Note the full paths.
2. **Record running state.** Check whether the app runs
   (`pgrep -fl <app>`, `osascript -e 'application "<App>" is running'`,
   `systemctl --user is-active <svc>`). Remember the answer - you must
   restore it at the end.
3. **Stop the app** if running (graceful quit first:
   `osascript -e 'quit app "<App>"'`, `systemctl --user stop`, `kill`
   only as last resort). Many apps rewrite config on exit, so stopping
   *before* the backup gives you the true current state.
4. **Back up** with `cp -a` (keep perms/timestamps) into the scratch dir
   as `backup/`. Verify the copy exists and is non-empty before going
   on - this backup is the user's only copy of their settings.
   For plists, also `defaults export <domain> backup.plist`, because
   `cfprefsd` caches values and the file alone can lie.
5. **Remove the config** (move it away, never `rm` the only copy). For
   plists use `defaults delete <domain>`.
6. **Generate defaults:** start the app, wait until it writes its config
   (poll for the file, a few seconds), then stop it again. Some apps only
   write config on exit or after a settings change, and some never write
   defaults at all. If no file appears, fall back to documented defaults
   (`man`, `<app> --help`, sample config shipped with the package, e.g.
   `$(brew --prefix)/opt/<app>/etc/...`) and tell the user.
   CLI tools can often dump defaults directly - prefer that and skip the
   start/stop dance (e.g. `mc` via `F9 > Options > Save setup`,
   `git config --list --show-origin`, `<app> --print-config`).
7. **Copy defaults** into the scratch dir as `default/`.
8. **Restore** - always, even if an earlier step failed. Ask the user
   which source to restore from:
   - **rebuild from the new Ansible tasks** (recommended) - apply the
     tasks you are about to write in step 10 by hand, *without* running
     `ansible-playbook`, on top of the freshly generated `default/`
     config. This proves the tasks really reproduce the user's setup.
     Do the diff (step 9) and write the tasks (step 10) first, then come
     back here. Afterwards `diff` the result against `backup/` and report
     every remaining difference, so the user can judge what the tasks
     still miss.
   - **restore `backup/` verbatim** - put the backup back in place
     (`defaults import` for plists) and verify it matches with
     `diff -r` / `cmp`.
   Either way: stop the app before replacing files, and start it again
   **only if it was running in step 2**. Keep `backup/` until the user
   confirms they are happy.
9. **Diff** `default/` vs `backup/` semantically, not just line by line:
   - ini: compare per section/option (`python3 -c 'import configparser'`)
   - JSON: `jq -S` both sides, then diff
   - plist: `plutil -convert json -o - <file> | jq -S`
   - TOML: `python3 -c 'import tomllib'` (3.11+), dump both sorted as
     JSON, then diff
   - YAML/other: parse if possible, else `diff -u`
   Ignore volatile noise: window geometry, timestamps, recent files,
   caches, last-used paths, machine IDs, update-check state. Show the
   user the filtered list and ask which to keep if anything is unclear.
10. **Write Ansible** for the kept options only (next section).

## Ansible output

Match this repo's style (see `ansible/tasks/common.yml`):

- ini → `community.general.ini_file` with a `loop` of
  `section`/`option`/`value`, `no_extra_spaces: true` if the app writes
  `key=value`, `mode:` set, list wrapped in
  `keep-sorted` start/end comment markers, values quoted strings.
- TOML → also `community.general.ini_file` (see OmniWM / topgrade in
  `tasks/MacOSX.yml`): keep the default `key = value` spacing (no
  `no_extra_spaces`), write values as TOML literals (`'"dwindle"'` for
  strings, `"true"`, `"0.0"`, arrays on one line via `to_json`), and use
  `keep-sorted` start markers with `block=yes`. Nested tables use the
  dotted section name (`section: a.b`). `ini_file` is line based, so
  multi-line arrays,
  inline tables or `[[array-of-tables]]` need `ansible.builtin.copy`
  of a template instead. If the app rejects partial files, guard the task
  with `ansible.builtin.stat` + `when: <var>.stat.exists`.
- plist → `community.general.osx_defaults` (domain, key, type, value).
- JSON → read, `combine(diff, recursive=true)` the diff, write back with
  `ansible.builtin.copy`
  (`content: "{{ ... | to_nice_json }}"`), or `ansible.builtin.lineinfile`
  for one-off keys.
- Other line-based formats → `ansible.builtin.lineinfile` with an
  anchored `regexp`.
- Add a `tags:` entry named after the app, put macOS-only tasks in
  `tasks/MacOSX.yml`, Fedora-only in `tasks/Fedora.yml`, shared in
  `tasks/common.yml`. Ensure the parent dir exists first
  (`ansible.builtin.file state: directory`).
- Tasks must be idempotent (CI runs the playbook twice and requires
  `changed=0`).
- Run `ansible-lint` from the repo root afterwards.

## Report back

Tell the user: config path(s), which options differ, which you dropped as
noise and why, where you put the tasks, which restore source they chose
(and, for the Ansible rebuild, what still differs from `backup/`), where
`backup/` lives, and confirm the app's running state matches what it was
before.
