# Verify a Devworks Server OS Release

Use this guide to verify downloaded ISO files before booting or installing them.

## 1. Download Release Assets

Download these files from the GitHub release:

```text
devworks-server-os.iso
devworks-server-os.iso.sha256
devworks-server-os.iso.asc
devworks-server-os-autoinstall.iso
devworks-server-os-autoinstall.iso.sha256
devworks-server-os-autoinstall.iso.asc
devworks-server-os-release-signing-key.asc
```

Optional but recommended:

```text
devworks-server-os-package-manifest.tsv
devworks-server-os-package-manifest.tsv.sha256
devworks-server-os-package-manifest.tsv.asc
```

## 2. Confirm Signing Key

Expected fingerprint:

```text
426072F517789C47A914345A4F53E388EE9884EA
```

Import the public key:

```bash
gpg --import devworks-server-os-release-signing-key.asc
gpg --fingerprint "Devworks Server OS Release"
```

Confirm the displayed fingerprint matches the expected fingerprint above.

## 3. Verify ISO Signatures

```bash
gpg --verify devworks-server-os.iso.asc devworks-server-os.iso
gpg --verify devworks-server-os-autoinstall.iso.asc devworks-server-os-autoinstall.iso
```

Expected result includes:

```text
Good signature from "Devworks Server OS Release <affandy21@users.noreply.github.com>"
```

## 4. Verify SHA256 Checksums

```bash
sha256sum -c devworks-server-os.iso.sha256
sha256sum -c devworks-server-os-autoinstall.iso.sha256
sha256sum -c devworks-server-os-package-manifest.tsv.sha256
```

Expected result:

```text
OK
```

## 5. Safety Reminder

The current installer mode is `erase-disk`. Do not install on a physical PC or server unless the target disk is backed up and you are certain the selected disk can be erased.

