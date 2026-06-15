#!/usr/bin/env bash
set -u

# Run on either DB server.
# This script diagnoses Patroni/PostgreSQL replication after functional SQL test failure.

CONFIG="${CONFIG:-/etc/patroni/patroni.yml}"
DB_NAME="${DB_NAME:-postgres}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-postgres}"
WRITE_HOST="${WRITE_HOST:-192.168.100.23}"
READ_HOST="${READ_HOST:-10.30.4.11}"

export PGPASSWORD="${DB_PASSWORD}"

run_sql() {
  local host="$1"
  local title="$2"
  local sql="$3"
  echo
  echo "### ${title} (${host})"
  psql -h "${host}" -U "${DB_USER}" -d "${DB_NAME}" -v ON_ERROR_STOP=0 -x -c "${sql}"
}

echo "[1/8] Patroni cluster list"
patronictl -c "${CONFIG}" list

echo
echo "[2/8] Patroni REST state"
echo "write node REST:"
curl -fsS "http://${WRITE_HOST}:8008" || true
echo
echo "read node REST:"
curl -fsS "http://${READ_HOST}:8008" || true
echo

echo
echo "[3/8] Basic PostgreSQL state"
for host in "${WRITE_HOST}" "${READ_HOST}"; do
  run_sql "${host}" "basic state" "
select
  inet_server_addr() as server_addr,
  inet_server_port() as server_port,
  pg_is_in_recovery() as in_recovery,
  case
    when pg_is_in_recovery() then pg_last_wal_receive_lsn()
    else pg_current_wal_lsn()
  end as receive_or_current_lsn,
  case
    when pg_is_in_recovery() then pg_last_wal_replay_lsn()
    else null
  end as replay_lsn,
  now() as checked_at;"
done

echo
echo "[4/8] Leader-side pg_stat_replication"
run_sql "${WRITE_HOST}" "write host pg_stat_replication" "
select
  pid, usename, application_name, client_addr, state,
  sent_lsn, write_lsn, flush_lsn, replay_lsn,
  write_lag, flush_lag, replay_lag,
  sync_state, reply_time
from pg_stat_replication;"

run_sql "${READ_HOST}" "read host pg_stat_replication" "
select
  pid, usename, application_name, client_addr, state,
  sent_lsn, write_lsn, flush_lsn, replay_lsn,
  write_lag, flush_lag, replay_lag,
  sync_state, reply_time
from pg_stat_replication;"

echo
echo "[5/8] Replica-side pg_stat_wal_receiver"
run_sql "${WRITE_HOST}" "write host pg_stat_wal_receiver" "
select
  pid, status, sender_host, sender_port,
  receive_start_lsn, written_lsn, flushed_lsn,
  latest_end_lsn, latest_end_time,
  slot_name, conninfo
from pg_stat_wal_receiver;"

run_sql "${READ_HOST}" "read host pg_stat_wal_receiver" "
select
  pid, status, sender_host, sender_port,
  receive_start_lsn, written_lsn, flushed_lsn,
  latest_end_lsn, latest_end_time,
  slot_name, conninfo
from pg_stat_wal_receiver;"

echo
echo "[6/8] Replication slots"
for host in "${WRITE_HOST}" "${READ_HOST}"; do
  run_sql "${host}" "replication slots" "
select slot_name, plugin, slot_type, database, active, active_pid, restart_lsn, confirmed_flush_lsn, wal_status
from pg_replication_slots
order by slot_name;"
done

echo
echo "[7/8] Patroni test tables visible on each node"
for host in "${WRITE_HOST}" "${READ_HOST}"; do
  run_sql "${host}" "patroni test tables" "
select schemaname, tablename
from pg_tables
where schemaname = 'public'
  and tablename like 'patroni_ha_test%'
order by tablename desc
limit 20;"
done

echo
echo "[8/8] Recent Patroni logs"
echo "Local host logs only:"
journalctl -u patroni -n 120 --no-pager || true

echo
echo "Diagnosis finished."
