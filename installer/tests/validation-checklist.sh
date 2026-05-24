#!/usr/bin/env bash
set -Eeuo pipefail

SSH_PORT="${SSH_PORT:-22}"
ADMIN_UI_PORT="${ADMIN_UI_PORT:-8088}"
AI_SERVICE_PORT="${AI_SERVICE_PORT:-11434}"
WEB_URL="${WEB_URL:-http://127.0.0.1/health}"
HTTPS_URL="${HTTPS_URL:-https://127.0.0.1/health}"
EXPECT_WEB="${DEVWORKS_EXPECT_WEB:-no}"
EXPECT_AI="${DEVWORKS_EXPECT_AI:-no}"

failures=0

check() {
  local name="$1"
  shift
  printf '[CHECK] %s ... ' "${name}"
  if "$@" >/tmp/devworks-check.out 2>/tmp/devworks-check.err; then
    printf 'ok\n'
  else
    printf 'failed\n'
    cat /tmp/devworks-check.err >&2 || true
    failures=$((failures + 1))
  fi
}

check "systemd running" systemctl is-system-running --wait
check "ssh active" systemctl is-active --quiet ssh
check "ufw status" ufw status verbose
check "no failed units" bash -c 'test "$(systemctl --failed --no-legend | wc -l)" -eq 0'
check "ssh port listening" bash -c "ss -tln | grep -q ':${SSH_PORT} '"
check "devworks feature manager" test -x /usr/local/sbin/devworks
check "dw short command" test -L /usr/local/sbin/dw

if [[ "${EXPECT_WEB}" == "yes" ]]; then
  check "nginx active" systemctl is-active --quiet nginx
  check "http health" curl -fsS "${WEB_URL}"
  if ss -tln | grep -q ':443 '; then
    check "https health" curl -kfsS "${HTTPS_URL}"
  fi
else
  check "nginx not enabled by default" bash -c '! systemctl is-enabled nginx >/dev/null 2>&1'
fi

if systemctl list-unit-files | grep -q '^devworks-admin-ui.service'; then
  check "admin ui active" systemctl is-active --quiet devworks-admin-ui
  check "admin ui port" bash -c "ss -tln | grep -q ':${ADMIN_UI_PORT} '"
fi

if [[ "${EXPECT_AI}" == "yes" ]] && systemctl list-unit-files | grep -q '^devworks-ai.service'; then
  check "ai service active" systemctl is-active --quiet devworks-ai
  check "ai service port" bash -c "ss -tln | grep -q ':${AI_SERVICE_PORT} '"
else
  check "ai not enabled by default" bash -c '! systemctl is-enabled devworks-ai.service >/dev/null 2>&1'
fi

check "journal high priority" bash -c '! journalctl -p err -b --no-pager | grep -E "failed|error|panic"'

rm -f /tmp/devworks-check.out /tmp/devworks-check.err

if [[ "${failures}" -gt 0 ]]; then
  echo "Validation failed: ${failures} checks failed." >&2
  exit 1
fi

echo "Validation passed."
