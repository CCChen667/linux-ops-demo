#!/usr/bin/env bash
set -Eeuo pipefail

APP_NAME="linux-ops-demo"
DEPLOY_ROOT="/srv/${APP_NAME}"
CURRENT_LINK="${DEPLOY_ROOT}/current"
NEXT_LINK="${DEPLOY_ROOT}/.current-next"

[[ "${EUID}" -eq 0 ]] || { echo "请使用 sudo bash scripts/rollback.sh" >&2; exit 1; }
[[ -L "${CURRENT_LINK}" ]] || { echo "尚无可回滚的当前版本" >&2; exit 1; }

current_target="$(readlink -f "${CURRENT_LINK}")"
mapfile -t releases < <(find "${DEPLOY_ROOT}/releases" -mindepth 1 -maxdepth 1 -type d -printf '%p\n' | sort -r)
rollback_target=""

for release in "${releases[@]}"; do
  if [[ "${release}" != "${current_target}" ]]; then
    rollback_target="${release}"
    break
  fi
done

[[ -n "${rollback_target}" ]] || { echo "没有更早的发布版本" >&2; exit 1; }

ln -sfn "${rollback_target}" "${NEXT_LINK}"
mv -Tf "${NEXT_LINK}" "${CURRENT_LINK}"
nginx -t
systemctl reload nginx
curl --fail --silent --show-error http://127.0.0.1:8088/health >/dev/null
printf 'Rollback succeeded: %s\n' "${rollback_target}"
