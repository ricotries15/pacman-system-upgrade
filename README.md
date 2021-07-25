# pacman-system-upgrade

Bash script that checks if there are any recents [Arch Linux news](https://archlinux.org/news/) before performing an Arch Linux system upgrade.

### Use case

It is easy to forget to check for recent news before upgrading packages using `pacman`, so this script removes the possibility that a system upgrade will be performed in an Arch Linux device without taking in consideration any special steps or warnings announced by the maintainers/developers.

### Usage

Source `pacman-system-upgrade.sh` in `/etc/bash.bashrc` or locally in `~/.bashrc` such as:

```bash
. /path/to/pacman-system-upgrade.sh
```

After this, any new Bash session will have the function `pacman-system-upgrade` available for execution, such as:

```bash
> pacman-system-upgrade
```
