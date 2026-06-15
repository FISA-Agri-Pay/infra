#!/usr/bin/env bash
set -euo pipefail

# Run on BOTH DB servers before stopping PostgreSQL.
# This script does not start Patroni and does not stop PostgreSQL.

CONFIG="${CONFIG:-/etc/patroni/patroni.yml}"
ETCD_URL="${ETCD_URL:-http://192.168.100.22:32379}"

echo "[1/8] Host information"
hostname
hostname -I || true

echo
echo "[2/8] Patroni binaries"
command -v patroni
command -v patronictl
patroni --version || true
patronictl version || true

echo
echo "[3/8] Patroni config file"
if [[ ! -f "${CONFIG}" ]]; then
  echo "Missing config: ${CONFIG}"
  exit 1
fi
ls -l "${CONFIG}"

echo
echo "[4/8] Patroni config validation"
if patroni --help 2>&1 | grep -q -- "--validate-config"; then
  set +e
  VALIDATION_OUTPUT="$(patroni --validate-config "${CONFIG}" 2>&1)"
  VALIDATION_STATUS=$?
  set -e
  if [[ "${VALIDATION_STATUS}" -eq 0 ]]; then
    echo "${VALIDATION_OUTPUT}"
  elif grep -q "Port 5432 is already in use" <<<"${VALIDATION_OUTPUT}"; then
    echo "${VALIDATION_OUTPUT}"
    echo
    echo "WARNING: Patroni config validation noticed that port 5432 is already in use."
    echo "This is expected before cutover because PostgreSQL is still running under systemd."
    echo "Continuing preflight."
  else
    echo "${VALIDATION_OUTPUT}"
    exit "${VALIDATION_STATUS}"
  fi
else
  echo "This Patroni version does not expose --validate-config; skipping syntax validation."
fi
echo
echo "[5/8] etcd health"
curl -fsS "${ETCD_URL}/health"
echo

echo
echo "[6/8] Port check"
echo "Port 5432 is expected to be in use by current PostgreSQL."
ss -ltnp | grep -E '(:5432|:8008)' || true
if ss -ltn | awk '{print $4}' | grep -Eq '(^|:)8008$'; then
  echo "ERROR: port 8008 is already in use. Patroni REST API needs this port."
  exit 1
fi
echo "OK: port 8008 is free."

echo
echo "[7/8] Current PostgreSQL state"
sudo -u postgres psql -Atc "select 'pg_is_in_recovery=' || pg_is_in_recovery();"
sudo -u postgres psql -Atc "show data_directory;" | sed 's/^/data_directory=/'
sudo -u postgres psql -Atc "show config_file;" | sed 's/^/config_file=/'
sudo -u postgres psql -Atc "show hba_file;" | sed 's/^/hba_file=/'
sudo -u postgres psql -Atc "show wal_level;" | sed 's/^/wal_level=/'
sudo -u postgres psql -Atc "show max_wal_senders;" | sed 's/^/max_wal_senders=/'
sudo -u postgres psql -Atc "show max_replication_slots;" | sed 's/^/max_replication_slots=/'
sudo -u postgres psql -Atc "show wal_log_hints;" | sed 's/^/wal_log_hints=/'
sudo -u postgres psql -Atc "show data_checksums;" | sed 's/^/data_checksums=/'

echo
echo "[8/8] Required roles"
sudo -u postgres psql -Atc "select rolname || ':login=' || rolcanlogin || ',replication=' || rolreplication from pg_roles where rolname in ('postgres', 'repl_user') order by rolname;"

echo
echo "Preflight finished."
echo "If this script succeeded on BOTH DB servers, the next step is the Patroni cutover window."
