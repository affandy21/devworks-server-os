# Verify a Devworks Server OS Release

Use this guide to verify downloaded ISO files before booting or installing them.

## 1. Download Release Assets

Download these files from the GitHub release:

```text
devworks-server-os.iso
devworks-server-os.iso.sha256
devworks-server-os.iso.asc
devworks-server-os-release-signing-key.asc
devworks-server-os-package-manifest.tsv
devworks-server-os-package-manifest.tsv.sha256
devworks-server-os-package-manifest.tsv.asc
```

The separately published `devworks-server-os-autoinstall.iso` is a legacy lab
asset for an empty disposable VirtualBox disk only. It is not the v0.2.1 media
for a physical server or a dual boot computer.

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
```

Expected result includes:

```text
Good signature from "Devworks Server OS Release <affandy21@users.noreply.github.com>"
```

## 4. Verify SHA256 Checksums

```bash
sha256sum -c devworks-server-os.iso.sha256
sha256sum -c devworks-server-os-package-manifest.tsv.sha256
```

Expected result:

```text
OK
```

## 5. Installer Mode and Safety

The standard ISO supports two intentional modes:

- `erase-disk` erases the confirmed target disk and is appropriate only for an empty dedicated server disk.
- `manual-partition` preserves an existing UEFI/EFI System Partition and formats only the explicitly selected Linux root partition. Use this for dual boot after shrinking Windows and creating a dedicated Linux partition.

Both modes require a typed confirmation. Back up important data first. The installer never resizes Windows partitions automatically, and the autoinstall ISO must not be used on a physical disk or any machine containing data.
