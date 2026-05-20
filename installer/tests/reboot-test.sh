#!/usr/bin/env bash
set -Eeuo pipefail

COUNT="${COUNT:-5}"
SSH_HOST="${SSH_HOST:-127.0.0.1}"
SSH_PORT="${SSH_PORT:-2222}"
SSH_USER="${SSH_USER:-devworks}"
SSH_OPTS=(
  -o StrictHostKeyChecking=no
  -o UserKnownHostsFile=/dev/null
  -o ConnectTimeout=5
  -p "${SSH_PORT}"
)

wait_for_ssh() {
  local attempt=1
  while [[ "${attempt}" -le 60 ]]; do
    if ssh "${SSH_OPTS[@]}" "${SSH_USER}@${SSH_HOST}" 'echo ok' >/dev/null 2>&1; then
      return 0
    fi
    sleep 5
    attempt=$((attempt + 1))
  done
  return 1
}

run_remote_validation() {
  ssh "${SSH_OPTS[@]}" "${SSH_USER}@${SSH_HOST}" 'sudo bash /usr/local/sbin/devworks-validation-checklist'
}

for i in $(seq 1 "${COUNT}"); do
  echo "=== Reboot test ${i}/${COUNT} ==="
  wait_for_ssh
  run_remote_validation
  ssh "${SSH_OPTS[@]}" "${SSH_USER}@${SSH_HOST}" 'sudo systemctl reboot' || true
  sleep 10
done

echo "Reboot test completed: ${COUNT} cycles."
