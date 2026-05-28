#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WIZARD="${PROJECT_DIR}/installer/devworks-installer-wizard.sh"
SOURCE_TMP="$(mktemp /tmp/devworks-wizard-source.XXXXXX)"
STDERR_TMP="$(mktemp /tmp/devworks-wizard-stderr.XXXXXX)"

cleanup() {
  rm -f "${SOURCE_TMP}" "${STDERR_TMP}"
}
trap cleanup EXIT

awk '$0 == "main \"$@\"" {next} {print}' "${WIZARD}" > "${SOURCE_TMP}"
source "${SOURCE_TMP}"

captured="$(printf 'irpan\n' | prompt_default "Username admin" "devworks" 2>"${STDERR_TMP}")"
[[ "${captured}" == "irpan" ]]
grep -Fq 'Username admin [devworks]:' "${STDERR_TMP}"

captured_default="$(printf '\n' | prompt_default "Username admin" "devworks" 2>/dev/null)"
[[ "${captured_default}" == "devworks" ]]

validate_linux_username "irpan"
validate_linux_username "devworks"
! validate_linux_username "Irpan"
! validate_linux_username "irpan affandy"
! validate_linux_username "irpan@example.com"

validate_hostname "devworks-server"
validate_hostname "server01"
! validate_hostname "devworks server"
! validate_hostname "devworks-server-"

echo "Wizard prompt static checks passed."
