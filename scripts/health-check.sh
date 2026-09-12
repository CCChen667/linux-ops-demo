#!/usr/bin/env bash
set -Eeuo pipefail

URL="${1:-http://127.0.0.1:8088/health}"
started_at="$(date +%s%3N)"

systemctl is-active --quiet nginx
payload="$(curl --fail --silent --show-error --max-time 10 "${URL}")"
finished_at="$(date +%s%3N)"
elapsed_ms="$((finished_at - started_at))"

if [[ "${payload}" != *'"status":"ok"'* ]]; then
  printf 'FAIL unexpected payload: %s\n' "${payload}" >&2
  exit 1
fi

printf 'PASS service=linux-ops-demo response_ms=%s checked_at=%s\n' \
  "${elapsed_ms}" "$(date --iso-8601=seconds)"
