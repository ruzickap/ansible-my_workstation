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

Use [Ansible](https://www.ansible.com/) to install+configure the software:

```bash
./run_ansible_macos_workstation-local.sh
```

### Configurations which needs to be done manually

There are few things which can not be done via scripts and must be done
manually in Catalina:

* Tap to click configuration: [https://osxdaily.com/2014/01/28/enable-tap-to-click-mac-trackpad/](https://osxdaily.com/2014/01/28/enable-tap-to-click-mac-trackpad/)
* Internet accounts
* Google Chrome
