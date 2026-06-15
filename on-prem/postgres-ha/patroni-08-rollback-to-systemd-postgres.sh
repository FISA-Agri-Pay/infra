#!/usr/bin/env bash
set -euo pipefail

# Emergency rollback helper.
# Run on a DB server if Patroni cutover fails and you want to bring back
# the original Debian PostgreSQL instance service.

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run with sudo/root."
  exit 1
fi

echo "[1/4] Stop Patroni if running"
systemctl stop patroni || true
systemctl disable patroni || true

echo
echo "[2/4] Start original PostgreSQL instance"
systemctl enable postgresql@16-main || true
systemctl start postgresql@16-main

echo
echo "[3/4] Status"
systemctl status postgresql@16-main --no-pager

echo
echo "[4/4] PostgreSQL recovery state"
sudo -u postgres psql -Atc "select 'pg_is_in_recovery=' || pg_is_in_recovery();"

echo
echo "Rollback helper finished."
