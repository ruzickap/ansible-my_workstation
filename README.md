# ansible-my_workstation

![fedora](https://github.com/ruzickap/ansible-my_workstation/workflows/fedora/badge.svg)
![macos](https://github.com/ruzickap/ansible-my_workstation/workflows/macos/badge.svg)

Configure my laptop with Ansible.

## MacOS Sonoma 14.2

* Initialize new MacBook Air 13.6" with macOS Sonoma 14.2
* Remove all applications which were preinstalled like "Box Sync", "Outlook",
  "OneDrive", "think-cell", ...
* Install [Brew](https://brew.sh/)
* Install Ansible: `brew install ansible`
* Restore the data (`Documents`, `Music`, `Pictures`, `.ssh`, ...) from backup
* Clone the repo, create `ansible/vault-my_workstation.password` file, add
  `MY_PASSWORD` to `./run_ansible_my_workstation-local-mac.sh` and run it

### Manual configurations

* Google Chrome + configure it (login, extensions, sync, ...)
  * uBock Origin -> Filter lists -> CZ
  * Google Translate -> My preferred languages -> Czech
  * Refined GitHub -> Personal token
  * Notifier for Gmail ->
    * Play alert sound for new emails
    * Open FAQs page on updates
  * KeePassXC -> General ->
    * Automatically fill in single-credential entries
    * Allow filling HTTP Basic Auth credentials
    * Show a banner on the page when new credentials can be saved to the database
  * KeePassXC -> Connected Databases
* Zoom
  * General -> Add Zoom to macOS menu bar
  * Video ->
    * Adjust for low light
    * Always display participant names on their video
    * Stop my video when joining a meeting
    * 49 participants
  * Share Screen -> Window size when screen sharing -> Maintain current size
  * Backgrounds & Effects -> Virtual Backgrounds
  * Recording -> Store my recordings at: `~/Desktop`
* Slack
* VS Code - [Move Search to panel](https://stackoverflow.com/questions/50058584/vs-code-toggle-search-icon-in-activity-bar-move-from-panel-or-back)
* iTerm2 -> Make iTerm2 Default Term
* OneDrive

  ```bash
  sudo rm -fr /Applications/OneDrive.app
  sudo touch /Applications/OneDrive.app
  sudo chflags schg /Applications/OneDrive.app
  ```

* MacOS
  * Apple ID
    * Disable synchronization of the Photos, iCloud Calendars, Reminders, Safari,
      Stocks, ...
  * Notifications
    * Allow notifications when the screen is locked
    * Slack -> Alerts
  * Sound -> Play sound on startup
  * Appearance -> Show scroll bars -> Always
  * Control Center ->
    * Battery -> Show in Menu Bar
    * Clock -> Show the day of the week
    * Spotlight
  * Privacy and Security -> Full Disk Access -> Add `~/Documents/backups/backup`
  * Screen Saver -> Shuffle All
  * Passwords -> Password Options -> Clean Up Automatically
  * Keyboard -> Keyboard Shortcuts -> Input Sources -> (uncheck all) [needed for
    Midnight Commander]
  * Trackpad -> Scroll & Zoom -> Zoom in or out

## Fedora

Download Fedora Server Netinst iso image:

```bash
wget https://download.fedoraproject.org/pub/fedora/linux/releases/32/Server/x86_64/iso/Fedora-Server-netinst-x86_64-32-1.6.iso -O ~/Documents/iso/
```

Rebuild the iso image:

```bash
./scripts/fedora_iso_rebuild.sh
```

Put generated image to USB stick:

```bash
dd if=~/Documents/iso/Fedora-Server-netinst-x86_64-32-1.6-my.iso of=/dev/sdb bs=8M
```

Boot the USB stick...

After the installation finish use `xxxx` as password to unlock the Disk (LUKS)
and login as `pruzicka` with `xxxx` password. Then run command:

```bash
/var/tmp/run.sh
```

## MacOS Catalina 10.5

Install new macOS Catalina 10.5 and enable ssh server:

* System Preferences from the Apple menu -> System Preferences -> Sharing
  -> Remote Login (checkbox)

  You can also do it the command-line way:

  ```bash
  sudo systemsetup -setremotelogin on
  ```

* Remove all applications which were preinstalled like "Google Chrome", "Zoom",
  "Slack", "Box Sync" or `~/.vim`.

* Ensure `sudo su` will give you the "root" access.

Use [Ansible](https://www.ansible.com/) to install+configure the software:

```bash
./run_ansible_macos_workstation-local.sh
# or
./run_ansible_my_workstation-local-mac.sh
```

Logout or better restart your macOS.

### Configurations which needs to be done manually

There are few things which can not be done via scripts and must be done
manually in Catalina:

* iCloud - enable "Find My Mac" only
* Internet Accounts - add Gmail account - enable "Calendars"
* Google Chrome (Login to Google services)
* IINA - prioritize external subs: [https://github.com/iina/iina/issues/816](https://github.com/iina/iina/issues/816)
* IINA - set as default video player
* iTerm2 - make iTerm2 default term
* Enable Security & Privacy Preferences -> Privacy -> Full Disk Access for
  `~/Documents/backups/backup` binary (recompile it if needed)
* Enable backup: `launchctl load ~/Library/LaunchAgents/backup.plist`
* For recording the audio from Zoom - create Multi-Output device with Master
  Device "Jabra Engage 75 2", Sample Rate: "48.0 KHz", Drift correction turned
  on for "BlackHole 16". Then you can use this as default output device in
  "Sound".
  Do not use "Jabra Engage 75" (microfone) as Input, because it can only use
  16 KHz and breaks the recording settings...
* Load extensions into Chrome: `~/Documents/chrome-extensions`
