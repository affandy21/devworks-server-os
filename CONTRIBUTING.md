# Contributing

Thank you for helping improve Devworks Server OS.

## Development Principles

- Keep the OS stable and boring at the system layer.
- Prefer Debian Stable packages and standard Linux mechanisms.
- Keep installer behavior explicit and auditable.
- Never add destructive disk behavior without manual confirmation in the standard ISO.
- Keep production-facing defaults secure.
- Document every user-visible operational change.

## Local Workflow

1. Create a branch.
2. Make a focused change.
3. Update documentation when behavior changes.
4. Run relevant validation scripts.
5. Test boot/install changes in VirtualBox before merging.

## Validation

Recommended checks:

```bash
bash installer/tests/validation-checklist.sh
sudo bash scripts/build-iso.sh
```

For installer changes, perform a VirtualBox install on an empty virtual disk and reboot at least three times.

## Pull Requests

Pull requests should include:

- What changed.
- Why it changed.
- How it was tested.
- Any migration or safety notes.
- Screenshots for GUI changes when useful.

