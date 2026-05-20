#!/usr/bin/env bash
set -euo pipefail

OUTPUT="${1:-devworks-package-manifest.tsv}"

if ! command -v dpkg-query >/dev/null 2>&1; then
  echo "dpkg-query not found. Run this on a Debian/Devworks installed system." >&2
  exit 1
fi

{
  printf 'package\tversion\tarchitecture\n'
  dpkg-query -W -f='${binary:Package}\t${Version}\t${Architecture}\n' | sort
} > "${OUTPUT}"

echo "Package manifest written to ${OUTPUT}"
