#!/usr/bin/env bash
set -euo pipefail

ETCD_HOST="${ETCD_HOST:-192.0.2.22}"
ETCD_PORT="${ETCD_PORT:-32379}"
ETCD_URL="http://${ETCD_HOST}:${ETCD_PORT}"

echo "[1/4] Host information"
hostname
hostname -I || true

echo
echo "[2/4] TCP connectivity check: ${ETCD_HOST}:${ETCD_PORT}"
if command -v nc >/dev/null 2>&1; then
  nc -zv "${ETCD_HOST}" "${ETCD_PORT}"
else
  timeout 3 bash -c "cat < /dev/null > /dev/tcp/${ETCD_HOST}/${ETCD_PORT}"
fi

echo
echo "[3/4] etcd HTTP health check: ${ETCD_URL}/health"
curl -fsS "${ETCD_URL}/health"
echo

echo
echo "[4/4] PostgreSQL local state snapshot"
sudo -u postgres psql -Atc "select 'pg_is_in_recovery=' || pg_is_in_recovery();"
sudo -u postgres psql -Atc "show data_directory;" | sed 's/^/data_directory=/'
sudo -u postgres psql -Atc "show wal_log_hints;" | sed 's/^/wal_log_hints=/'
sudo -u postgres psql -Atc "show data_checksums;" | sed 's/^/data_checksums=/'

echo
echo "OK: this DB server can reach Patroni etcd if all checks above passed."
