#!/usr/bin/env bash
set -Eeuo pipefail

ISO_PATH="${1:-dist/devworks-server-os.iso}"
OUTPUT="${2:-dist/devworks-server-os-package-manifest.tsv}"
WORK_DIR="$(mktemp -d /tmp/devworks-iso-manifest.XXXXXX)"

cleanup() {
  rm -rf "${WORK_DIR}"
}
trap cleanup EXIT

for command in xorriso unsquashfs dpkg-query sort; do
  command -v "${command}" >/dev/null 2>&1 || {
    echo "Missing manifest command: ${command}" >&2
    exit 1
  }
done

[[ -f "${ISO_PATH}" ]] || {
  echo "ISO not found: ${ISO_PATH}" >&2
  exit 1
}

mkdir -p "$(dirname "${OUTPUT}")"
xorriso -osirrox on -indev "${ISO_PATH}" \
  -extract /live/filesystem.squashfs "${WORK_DIR}/filesystem.squashfs" >/dev/null 2>&1
unsquashfs -no-progress -d "${WORK_DIR}/root" "${WORK_DIR}/filesystem.squashfs" >/dev/null

{
  printf 'package\tversion\tarchitecture\n'
  dpkg-query --admindir="${WORK_DIR}/root/var/lib/dpkg" -W \
    -f='${binary:Package}\t${Version}\t${Architecture}\n' | sort
} > "${OUTPUT}"

echo "ISO package manifest written to ${OUTPUT}"
