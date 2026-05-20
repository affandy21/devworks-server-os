# Third-Party Notices

Devworks Server OS is a custom Linux operating system built from Devworks project files and third-party open source components.

This document identifies important upstream projects and source/license locations. It is provided for attribution and compliance hygiene. It is not legal advice.

## Core Upstream Projects

### Linux Kernel

Devworks Server OS uses the Linux kernel packages provided by Debian.

- Project: Linux kernel
- Website: https://www.kernel.org/
- Documentation: https://www.kernel.org/doc/
- License information: https://www.kernel.org/doc/html/latest/process/license-rules.html
- Source repository: https://git.kernel.org/

The Linux kernel is generally distributed under GPL-2.0-only, with additional notices and exceptions documented by the kernel project.

### Debian

Devworks Server OS is based on Debian Stable packages.

- Project: Debian
- Website: https://www.debian.org/
- License information: https://www.debian.org/legal/licenses/
- Debian package source browser: https://sources.debian.org/
- Debian package search: https://packages.debian.org/

Debian packages are distributed under many different open source licenses. Each package's exact license information is normally available in:

```text
/usr/share/doc/<package>/copyright
```

inside the installed system.

### GNU Project

Many base system utilities are provided by GNU packages.

- Project: GNU
- Website: https://www.gnu.org/
- Licenses: https://www.gnu.org/licenses/

### systemd

Devworks Server OS uses systemd as the service manager through Debian packages.

- Project: systemd
- Website: https://systemd.io/
- Source: https://github.com/systemd/systemd

### XFCE

The graphical desktop uses XFCE packages from Debian.

- Project: XFCE
- Website: https://www.xfce.org/
- Source: https://gitlab.xfce.org/

### LightDM

The graphical login manager uses LightDM packages from Debian.

- Project: LightDM
- Source: https://github.com/canonical/lightdm

### OpenSSH

SSH access is provided by OpenSSH packages from Debian.

- Project: OpenSSH
- Website: https://www.openssh.com/

### Nginx

The default web server/reverse proxy component uses Nginx packages from Debian.

- Project: Nginx
- Website: https://nginx.org/

### UFW

Firewall management uses UFW packages from Debian.

- Project: UFW
- Source: https://launchpad.net/ufw

### Fail2ban

Brute-force protection uses Fail2ban packages from Debian.

- Project: Fail2ban
- Source: https://github.com/fail2ban/fail2ban

## Devworks-Specific Components

The following components are Devworks project files:

- Devworks installer scripts.
- Devworks Control Center.
- Devworks desktop integration files.
- Devworks documentation.
- Devworks branding assets, icons, and wallpapers.

These files are covered by the repository license unless otherwise noted.

## Trademark Notice

Linux is the registered trademark of Linus Torvalds in the U.S. and other countries.

Debian is a trademark of Software in the Public Interest, Inc.

Other names may be trademarks of their respective owners. Devworks Server OS is not endorsed by Debian, Linus Torvalds, kernel.org, XFCE, or any other upstream project unless explicitly stated.

## Source Requests

Source-code and compliance requests for Devworks-specific files can be submitted through:

```text
https://github.com/affandy21/devworks-server-os/issues/new/choose
```
