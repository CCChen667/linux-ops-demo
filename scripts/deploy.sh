#!/usr/bin/env bash
set -Eeuo pipefail

APP_NAME="linux-ops-demo"
DEPLOY_ROOT="/srv/${APP_NAME}"
KEEP_RELEASES="${KEEP_RELEASES:-5}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
RELEASE_ID="$(date -u +%Y%m%dT%H%M%SZ)"
RELEASE_DIR="${DEPLOY_ROOT}/releases/${RELEASE_ID}"
CURRENT_LINK="${DEPLOY_ROOT}/current"
NEXT_LINK="${DEPLOY_ROOT}/.current-next"
NGINX_SITE="/etc/nginx/sites-available/${APP_NAME}"
NGINX_ENABLED="/etc/nginx/sites-enabled/${APP_NAME}"

log() { printf '[deploy] %s\n' "$*"; }
fail() { printf '[deploy] ERROR: %s\n' "$*" >&2; exit 1; }

[[ "${EUID}" -eq 0 ]] || fail "请使用 sudo bash scripts/deploy.sh"
[[ -f "${PROJECT_ROOT}/public/index.html" ]] || fail "缺少 public/index.html"
[[ -f "${PROJECT_ROOT}/nginx/${APP_NAME}.conf" ]] || fail "缺少 Nginx 配置"
[[ "${KEEP_RELEASES}" =~ ^[1-9][0-9]*$ ]] || fail "KEEP_RELEASES 必须是正整数"

log "创建发布版本 ${RELEASE_ID}"
install -d -m 0755 "${DEPLOY_ROOT}/releases"
install -d -m 0755 "${RELEASE_DIR}/public"
cp -a "${PROJECT_ROOT}/public/." "${RELEASE_DIR}/public/"
chown -R root:root "${RELEASE_DIR}"
find "${RELEASE_DIR}" -type d -exec chmod 0755 {} +
find "${RELEASE_DIR}" -type f -exec chmod 0644 {} +

log "安装并验证 Nginx 配置"
install -m 0644 "${PROJECT_ROOT}/nginx/${APP_NAME}.conf" "${NGINX_SITE}"
ln -sfn "${NGINX_SITE}" "${NGINX_ENABLED}"
nginx -t

log "原子切换 current 软链接"
ln -sfn "${RELEASE_DIR}" "${NEXT_LINK}"
mv -Tf "${NEXT_LINK}" "${CURRENT_LINK}"

if systemctl is-active --quiet nginx; then
  systemctl reload nginx
else
  systemctl enable --now nginx
fi

log "运行健康检查"
health_payload="$(curl --fail --silent --show-error --max-time 10 http://127.0.0.1:8088/health)"
[[ "${health_payload}" == *'"status":"ok"'* ]] || fail "健康检查内容异常: ${health_payload}"

mapfile -t old_releases < <(find "${DEPLOY_ROOT}/releases" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -r | tail -n "+$((KEEP_RELEASES + 1))")
for release in "${old_releases[@]:-}"; do
  [[ -n "${release}" ]] && rm -rf -- "${DEPLOY_ROOT}/releases/${release}"
done

log "发布成功: ${RELEASE_DIR}"
log "访问地址: http://localhost:8088"
