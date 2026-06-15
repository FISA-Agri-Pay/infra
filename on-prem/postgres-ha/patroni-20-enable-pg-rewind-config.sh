#!/usr/bin/env bash
set -euo pipefail

# Run on either DB server.
# This enables Patroni pg_rewind support in the DCS and sets wal_log_hints=on.
# wal_log_hints requires a PostgreSQL restart, so run patroni-21 after this.

CONFIG="${CONFIG:-/etc/patroni/patroni.yml}"
CLUSTER="${CLUSTER:-pg-cluster}"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "ERROR: missing command: $1"; exit 1; }
}

need_cmd patronictl
need_cmd psql

echo "[1/5] Current Patroni cluster state"
patronictl -c "${CONFIG}" list

echo
echo "[2/5] Current dynamic config"
patronictl -c "${CONFIG}" show-config || true

echo
echo "[3/5] Local PostgreSQL rewind prerequisites"
sudo -u postgres psql -Atc "select 'wal_log_hints=' || current_setting('wal_log_hints');"
sudo -u postgres psql -Atc "select 'data_checksums=' || current_setting('data_checksums');"

echo
echo "[4/5] Update Patroni DCS dynamic config"
patronictl -c "${CONFIG}" edit-config "${CLUSTER}" \
  --set postgresql.use_pg_rewind=true \
  --set postgresql.parameters.wal_log_hints=on \
  --force

echo
echo "[5/5] Updated dynamic config"
patronictl -c "${CONFIG}" show-config

echo
echo "OK: pg_rewind was enabled in Patroni DCS and wal_log_hints=on was requested."
echo "Next step: run patroni-21-rolling-restart-for-pg-rewind.sh on either DB server."
