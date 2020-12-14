# ansible-my_workstation

![fedora](https://github.com/ruzickap/ansible-my_workstation/workflows/fedora/badge.svg)
![macos](https://github.com/ruzickap/ansible-my_workstation/workflows/macos/badge.svg)

Configure my laptop with Ansible.

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

Install new MacOS Catalina 10.5 and enable ssh server:

* System Preferences from the Apple menu -> System Preferences -> Sharing
  -> Remote Login (checkbox)

  You can also do it the command line way:

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

Logout or better restart your MacOS.

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

## Notes

Test pages:

* [https://html5test.com/](https://html5test.com/)
* [https://bitmovin.com/demos/drm](https://bitmovin.com/demos/drm)
