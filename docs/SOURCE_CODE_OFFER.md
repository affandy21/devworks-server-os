# Source Code Offer

Devworks Server OS distributes a bootable ISO assembled from Devworks project files and Debian binary packages.

This document explains how recipients can obtain corresponding source code for the Devworks-specific files and for third-party open source packages. It is not legal advice.

## Devworks Project Source

Devworks-specific scripts, configuration, GUI code, and documentation are available in this repository:

```text
https://github.com/affandy21/devworks-server-os
```

Release source archives are also available from GitHub releases/tags.

## Debian Package Sources

Most third-party software in the ISO comes from Debian Stable package repositories.

Debian source packages can be obtained from:

```text
https://sources.debian.org/
https://packages.debian.org/
```

On a Debian system with source repositories enabled, source packages can also be downloaded with:

```bash
apt source PACKAGE_NAME
```

Example:

```bash
apt source linux
apt source systemd
apt source openssh
apt source nginx
```

If `apt source` reports that source repositories are not enabled, add matching `deb-src` entries for the Debian release used by the ISO, then run:

```bash
sudo apt update
```

## Installed Package License Files

In an installed Devworks Server OS system, Debian package copyright and license files are generally available under:

```text
/usr/share/doc/<package>/copyright
```

Examples:

```bash
less /usr/share/doc/linux-image-amd64/copyright
less /usr/share/doc/systemd/copyright
less /usr/share/doc/openssh-server/copyright
less /usr/share/doc/nginx/copyright
```

## Package Manifest

For future releases, Devworks Server OS should publish a package manifest generated from the final ISO or installed system, for example:

```bash
dpkg-query -W -f='${binary:Package}\t${Version}\t${Architecture}\n' > devworks-package-manifest.tsv
```

The manifest helps users identify exact package versions and retrieve corresponding source packages.

This repository includes a helper script:

```bash
bash scripts/generate-package-manifest.sh devworks-package-manifest.tsv
```

## Kernel Source

Devworks Server OS uses Debian Linux kernel packages unless a future release explicitly states otherwise.

Relevant upstream links:

```text
https://www.kernel.org/
https://git.kernel.org/
https://www.kernel.org/doc/html/latest/process/license-rules.html
https://sources.debian.org/
```

If a future Devworks release modifies the Linux kernel itself, the complete corresponding modified kernel source must be published or offered according to the applicable license obligations.

## Written Requests

For a public preview release, users should first use the repository and Debian source links above.

For production distribution, Devworks should maintain a formal source request contact such as:

```text
source-request@example.com
```

Replace that placeholder with a real monitored address before commercial or wide public distribution.
