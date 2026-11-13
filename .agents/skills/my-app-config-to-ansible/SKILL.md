---
name: my-app-config-to-ansible
description: >-
  Turn an app's existing configuration (ini, toml, json, yaml, xml, plist,
  conf, sqlite-backed prefs, macOS defaults domains) into Ansible tasks that
  set only the settings which differ from the app's own defaults. Works by
  quitting the app, backing up its config to a tmp dir, wiping it, letting the
  app regenerate pristine defaults, diffing the two, and writing the diff as
  idempotent Ansible (ini_file, osx_defaults, lineinfile, copy/template).
  Use whenever the user wants to convert, "ansible-ize", capture, codify,
  reproduce or automate an app's settings - e.g. "convert the configuration of
  <app> to ansible", "add my iTerm2/VS Code/Ghostty/mc/kitty settings to the
  playbook", "what did I change in this app", "generate ansible for this
  config file", "diff this config against defaults" - even if they only say
  "put my current app setup into ansible". Also use it to pick up changes made
  since the last run - e.g. "I did some changes in <app> configuration,
  extract them into my ansible code", "sync my <app> settings back into the
  playbook", "update the ansible tasks with what I changed in <app>".
license: Apache-2.0
---

# App config → Ansible

Goal: Ansible that configures an app with **only** the settings the user
actually changed. Shipping the whole config file as `copy:` buries the three
real changes under 200 defaults, breaks on app upgrades, and loses settings
the app writes at runtime. Diffing against freshly generated defaults is the
only reliable way to know what is intentional.

This destroys live configuration. The backup in the tmp dir is the user's
only copy - make it first, verify it, and never delete it yourself.

## 1. Locate every config the app owns

Ask the user for the app name, then find its state. Don't guess from one
location - apps scatter config.

macOS:

```bash
# adjust the app name / bundle id below
ls -d ~/Library/Preferences/*ghostty* ~/Library/Application\ Support/*Ghostty* \
  ~/Library/Containers/*ghostty* ~/Library/Saved\ Application\ State/*ghostty* \
  ~/.config/ghostty ~/.ghostty* 2> /dev/null
defaults domains | tr ',' '\n' | grep -i ghostty
```

Linux: `~/.config/<app>`, `~/.local/share/<app>`, `~/.<app>rc`, `/etc/<app>`.

Cross-check with the app's docs (use context7 or the web) when the layout is
unclear, and show the user the list before touching anything. Treat
history/cache/state/logs/sqlite session stores as **not** config - note them,
but they don't belong in Ansible.

## 2. Quit the app, then back up

The app holds settings in memory and writes them on exit, so capturing a
running app gives a stale file.

```bash
osascript -e 'quit app "Ghostty"' # macOS; or: pkill -x ghostty
BACKUP="${TMPDIR:-/tmp}/ansible-config-ghostty-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP/current"
# copy every path found in step 1, keeping structure
cp -a ~/.config/ghostty "$BACKUP/current/"
defaults export com.mitchellh.ghostty "$BACKUP/current/com.mitchellh.ghostty.plist"
```

Confirm the app is gone (`pgrep -x`), then verify the backup **per path and
per domain**: every config path from step 1 exists under `$BACKUP/current/`
and every `defaults export` exited 0 with a non-empty plist. Never wipe
anything that is not in the backup. Tell the user the backup path - they
will want it.

## 3. Wipe, restart, capture defaults

```bash
rm -rf ~/.config/ghostty
defaults delete com.mitchellh.ghostty 2> /dev/null
open -a Ghostty # or run the binary once
```

Give the app time to initialise and ask the user to confirm it reached its
normal first-run state (some apps only write defaults on first quit, so quit
it again before capturing). Then copy the pristine config to
`$BACKUP/defaults/` the same way.

If an app writes nothing on its own, its "default" is the absence of a key -
that still works for the diff, every key in the backup counts as changed.

## 4. Diff

```bash
diff -ru "$BACKUP/defaults" "$BACKUP/current"
plutil -convert xml1 -o - file.plist # make plists diffable first
```

Normalise before comparing so formatting noise doesn't look like a change:
convert binary plists to xml, pretty-print JSON (`jq -S .`), sort keys.

Then classify every difference, and show the user this table:

| setting | default | user value | keep? |

Drop machine-specific or runtime values - window geometry, recent files,
device/display IDs, tokens, licence keys, install paths, timestamps, UUIDs.
Never put a secret into the playbook. When in doubt, ask.

**A key in the diff is not proof the user changed it.** Many apps persist
every option of a settings pane the moment it is opened, so the file fills up
with values identical to the app's own default. Before keeping a key, check
the real default in the app's source (open-source apps: the field initialiser
and the `defaultValue:` of its store lookup, plus any per-module config file
that overrides it) or its docs. Drop keys that merely restate the default -
they are noise that will silently fight a future upstream change. Keys whose
value is obviously a deliberate choice (a widget/theme selection, a
threshold) need no lookup.

Ordering/position keys (`*_position`, widget order) are usually written as a
side effect of visiting the settings UI - drop them unless the user actually
reordered something.

## 5. Write the Ansible

Match the surrounding playbook exactly - read the target file first
(`ansible/tasks/MacOSX.yml`, `tasks/Fedora.yml`, `tasks/common.yml`) and copy
its conventions: two-space indent, FQCN modules, `mode: u=rw,g=r,o=r`,
`keep-sorted` blocks (insert in sorted order), and the repo's tag scheme.

Pick the module by format, preferring surgical over whole-file:

| format                      | module                                                                                                   |
|-----------------------------|----------------------------------------------------------------------------------------------------------|
| ini / toml / conf           | `community.general.ini_file` (one loop item per setting)                                                 |
| macOS defaults domain       | `community.general.osx_defaults` (set `type`)                                                            |
| json / yaml                 | read + `combine` + `ansible.builtin.copy` with `to_nice_json`, or `jq` via `command` with `changed_when` |
| xml                         | `community.general.xml` with `xpath`                                                                     |
| single-line rc files        | `ansible.builtin.lineinfile`                                                                             |
| file the app never rewrites | `ansible.builtin.copy` / `template` from `ansible/files/...`                                             |

Only reach for a whole-file `copy:` when the app rejects partial files or the
diff is most of the file - and say why in a one-line comment, like the OmniWM
task does.

Whole-file configs go under `ansible/files/home/myusername/...` (Linux) or
`ansible/files/Users/myusername/...` (macOS), `.j2` only if it needs
variables.

Idempotence is enforced by CI (the playbook runs twice, second run must be
`changed=0`), so prefer declarative modules; any `command`/`shell` needs
`changed_when` or `creates`.

## 6. Hand back control

Two paths - **ask, don't pick for them**:

1. **Restore from backup** - quit the app, `cp -a "$BACKUP/current/."
   <original locations>` and `defaults import <domain>
   "$BACKUP/current/<domain>.plist"` for every exported domain (copying the
   export back does *not* restore it), then `killall cfprefsd` and restart
   the app. Fastest way back to a working app; the generated Ansible stays as
   a patch for review.
2. **Apply via Ansible** - run only this app's tasks, nothing else:

   ```bash
   cd ansible && ansible-playbook --tags ghostty --skip-tags data \
     --connection=local -i "127.0.0.1," main.yml
   ```

   This needs a tag on the new tasks; add one if the app has none. The
   `include_tasks` dispatcher in `ansible/main.yml` carries `tags: always` so
   tagged runs reach the OS task file - check the output actually lists your
   tasks, because a run that skips them also reports `changed=0`. Never run
   the full playbook to test one app.

Then verify: start the app, confirm the settings look right, and re-run the
same tagged playbook to prove it reports `changed=0`. If it doesn't, the task
isn't idempotent - fix it before finishing.

**If any step after the wipe fails or is interrupted**, restore the backup
(path 1 above) before handing back control - never leave the user with reset
settings.

Finish by telling the user the backup path and that it is still there.

## Pitfalls

- macOS caches preferences in `cfprefsd`; after editing a plist by hand run
  `killall cfprefsd` or the app will overwrite your change.
- Sandboxed apps read from `~/Library/Containers/<id>/Data/...`, not the
  plain home path - the symlinked-looking path is the real one.
- Some apps write defaults only after the *second* launch, or on quit.
- An app upgrade can add new default keys; a diff captured today may list a
  key that becomes the default tomorrow. That is fine - `ini_file` and
  `osx_defaults` just keep asserting it.
- Re-running this skill later on the same app: reuse the `defaults/` snapshot
  from the earlier backup instead of wiping again, as long as the app version
  is unchanged.
