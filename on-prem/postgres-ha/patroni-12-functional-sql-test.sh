#!/usr/bin/env bash
set -euo pipefail

# Run on either DB server after Patroni switchover tests succeed.
# This creates a small test table in the postgres database, writes to the
# current leader, and verifies that the row appears on the replica.

CONFIG="${CONFIG:-/etc/patroni/patroni.yml}"
DB_NAME="${DB_NAME:-postgres}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-postgres}"
WRITE_HOST="${WRITE_HOST:-192.168.100.23}"
READ_HOST="${READ_HOST:-10.30.4.11}"
WRITE_NODE="${WRITE_NODE:-postgresql-write}"
READ_NODE="${READ_NODE:-postgresql-read}"
TABLE_PREFIX="${TABLE_PREFIX:-patroni_ha_test}"

export PGPASSWORD="${DB_PASSWORD}"

echo "[1/6] Patroni cluster state"
patronictl -c "${CONFIG}" list

echo
echo "[2/6] Detect current leader"
LEADER="$(patronictl -c "${CONFIG}" list -f json | python3 -c 'import json, sys; rows=json.load(sys.stdin); print(next((r.get("Member", "") for r in rows if r.get("Role") == "Leader"), ""))')"

if [[ -z "${LEADER}" ]]; then
  echo "ERROR: could not detect Patroni leader."
  exit 1
fi

case "${LEADER}" in
  "${WRITE_NODE}")
    LEADER_HOST="${WRITE_HOST}"
    REPLICA_HOST="${READ_HOST}"
    ;;
  "${READ_NODE}")
    LEADER_HOST="${READ_HOST}"
    REPLICA_HOST="${WRITE_HOST}"
    ;;
  *)
    echo "ERROR: unknown leader member: ${LEADER}"
    exit 1
    ;;
esac

echo "Leader member: ${LEADER}"
echo "Leader host:   ${LEADER_HOST}"
echo "Replica host:  ${REPLICA_HOST}"

echo
TEST_ID="$(date +%Y%m%d%H%M%S)"
TABLE_NAME="${TABLE_PREFIX}_${TEST_ID}"
MARKER="patroni-test-${TEST_ID}"

echo "[3/6] Create fresh test table on leader: public.${TABLE_NAME}"
psql -h "${LEADER_HOST}" -U "${DB_USER}" -d "${DB_NAME}" -v ON_ERROR_STOP=1 <<SQL
create table public.${TABLE_NAME} (
  id bigserial primary key,
  marker text not null,
  created_at timestamptz not null default now()
);
SQL

echo
echo "[4/6] Insert test row on leader: ${MARKER}"
psql -h "${LEADER_HOST}" -U "${DB_USER}" -d "${DB_NAME}" -v ON_ERROR_STOP=1 <<SQL
insert into public.${TABLE_NAME} (marker) values ('${MARKER}');
SQL

echo
echo "[5/6] Wait for replica to receive the table and row"
for i in {1..60}; do
  TABLE_EXISTS="$(psql -h "${REPLICA_HOST}" -U "${DB_USER}" -d "${DB_NAME}" -Atc "select to_regclass('public.${TABLE_NAME}') is not null;")"
  if [[ "${TABLE_EXISTS}" == "t" ]]; then
    COUNT="$(psql -h "${REPLICA_HOST}" -U "${DB_USER}" -d "${DB_NAME}" -Atc "select count(*) from public.${TABLE_NAME} where marker='${MARKER}';")"
    if [[ "${COUNT}" == "1" ]]; then
      echo "Replica has the table and row."
      break
    fi
  fi
  sleep 1
  if [[ "$i" -eq 60 ]]; then
    echo "ERROR: replica did not receive table public.${TABLE_NAME} and marker ${MARKER} within 60 seconds."
    echo
    echo "Leader WAL position:"
    psql -h "${LEADER_HOST}" -U "${DB_USER}" -d "${DB_NAME}" -Atc "select pg_current_wal_lsn();" || true
    echo
    echo "Replica WAL receiver:"
    psql -h "${REPLICA_HOST}" -U "${DB_USER}" -d "${DB_NAME}" -x -c "select status, sender_host, sender_port, latest_end_lsn, latest_end_time, slot_name from pg_stat_wal_receiver;" || true
    exit 1
  fi
done

echo
echo "[6/6] Final check"
echo "Leader row:"
psql -h "${LEADER_HOST}" -U "${DB_USER}" -d "${DB_NAME}" -c "select * from public.${TABLE_NAME} where marker='${MARKER}';"
echo
echo "Replica row:"
psql -h "${REPLICA_HOST}" -U "${DB_USER}" -d "${DB_NAME}" -c "select * from public.${TABLE_NAME} where marker='${MARKER}';"

echo
echo "OK: SQL write on leader and read from replica succeeded."
