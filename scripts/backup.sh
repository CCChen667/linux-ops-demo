#!/usr/bin/env bash
set -Eeuo pipefail

APP_NAME="linux-ops-demo"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
BACKUP_ROOT="${BACKUP_ROOT:-/mnt/d/Codex/backups/${APP_NAME}}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
ARCHIVE="${BACKUP_ROOT}/${APP_NAME}-${STAMP}.tar.gz"

mkdir -p -- "${BACKUP_ROOT}"
tar --exclude='.git' --exclude='*.tar.gz' -czf "${ARCHIVE}" -C "${PROJECT_ROOT}" .
sha256sum "${ARCHIVE}" > "${ARCHIVE}.sha256"

printf 'Backup: %s\n' "${ARCHIVE}"
printf 'Checksum: %s\n' "${ARCHIVE}.sha256"
