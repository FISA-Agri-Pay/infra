#!/usr/bin/env bash
set -euo pipefail

# Run on either DB server after both Patroni nodes are started.

CONFIG="${CONFIG:-/etc/patroni/patroni.yml}"
PRIMARY_REST="${PRIMARY_REST:-http://192.0.2.23:8008}"
REPLICA_REST="${REPLICA_REST:-http://198.51.100.11:8008}"

echo "[1/7] Host information"
hostname
hostname -I || true

echo
echo "[2/7] Patroni service"
systemctl is-active patroni
systemctl status patroni --no-pager || true

echo
echo "[3/7] Original PostgreSQL instance service should be inactive"
systemctl is-active postgresql@16-main || true
systemctl is-enabled postgresql@16-main || true

echo
echo "[4/7] Patroni REST API checks"
echo "Primary candidate REST: ${PRIMARY_REST}"
curl -fsS "${PRIMARY_REST}" || true
echo
echo "Replica candidate REST: ${REPLICA_REST}"
curl -fsS "${REPLICA_REST}" || true
echo

echo
echo "[5/7] Patroni cluster list"
patronictl -c "${CONFIG}" list

echo
echo "[6/7] Local PostgreSQL role"
sudo -u postgres psql -Atc "select 'pg_is_in_recovery=' || pg_is_in_recovery();"
sudo -u postgres psql -Atc "select 'server_addr=' || inet_server_addr() || ', server_port=' || inet_server_port();"

echo
echo "[7/7] Replication views"
echo "pg_stat_replication:"
sudo -u postgres psql -x -c "select pid, usename, application_name, client_addr, state, sent_lsn, write_lsn, flush_lsn, replay_lsn, sync_state, reply_time from pg_stat_replication;"
echo
echo "pg_stat_wal_receiver:"
sudo -u postgres psql -x -c "select pid, status, sender_host, sender_port, latest_end_lsn, latest_end_time, slot_name from pg_stat_wal_receiver;"

echo
echo "Verification finished."
echo "Expected cluster shape:"
echo "  postgresql-write = Leader"
echo "  postgresql-read  = Replica"
