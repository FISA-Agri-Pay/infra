#!/usr/bin/env bash
set -euo pipefail

# Run SECOND on the current replica/read DB server: 198.51.100.11
# This stops the Debian PostgreSQL instance service and starts Patroni.

CONFIG="${CONFIG:-/etc/patroni/patroni.yml}"
ETCD_URL="${ETCD_URL:-http://192.0.2.22:32379}"
PRIMARY_REST="${PRIMARY_REST:-http://192.0.2.23:8008}"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run with sudo/root."
  exit 1
fi

echo "[1/10] Host check"
hostname
hostname -I || true

echo
echo "[2/10] Confirm this server is currently replica"
IS_IN_RECOVERY="$(sudo -u postgres psql -Atc "select pg_is_in_recovery();")"
echo "pg_is_in_recovery=${IS_IN_RECOVERY}"
if [[ "${IS_IN_RECOVERY}" != "t" ]]; then
  echo "ERROR: this server is not currently a replica. Stop."
  exit 1
fi

echo
echo "[3/10] etcd check"
curl -fsS "${ETCD_URL}/health"
echo

echo
echo "[4/10] Primary Patroni REST check"
curl -fsS "${PRIMARY_REST}/primary" >/dev/null
echo "Primary Patroni REST API is reachable: ${PRIMARY_REST}/primary"

echo
echo "[5/10] Patroni DCS command check"
patronictl -c "${CONFIG}" list

echo
echo "[6/10] Port check before cutover"
ss -ltnp | grep -E '(:5432|:8008)' || true
if ss -ltn | awk '{print $4}' | grep -Eq '(^|:)8008$'; then
  echo "ERROR: port 8008 is already in use."
  exit 1
fi

echo
echo "[7/10] Install Patroni systemd unit"
bash "$(dirname "$0")/patroni-05-install-service-on-db.sh"

echo
echo "[8/10] Stop and disable existing PostgreSQL instance service"
systemctl stop postgresql@16-main
systemctl disable postgresql@16-main || true
systemctl disable postgresql || true

echo
echo "[9/10] Start Patroni"
systemctl enable patroni
systemctl start patroni

echo
echo "[10/10] Wait for Patroni replica REST API"
for i in {1..30}; do
  if curl -fsS http://127.0.0.1:8008/replica >/dev/null 2>&1; then
    echo "Patroni reports this node as replica."
    break
  fi
  sleep 2
  if [[ "$i" -eq 30 ]]; then
    echo "ERROR: Patroni did not become replica in time."
    systemctl status patroni --no-pager || true
    journalctl -u patroni -n 80 --no-pager || true
    exit 1
  fi
done

echo
systemctl status patroni --no-pager
echo
patronictl -c "${CONFIG}" list
echo
sudo -u postgres psql -Atc "select 'pg_is_in_recovery=' || pg_is_in_recovery();"

echo
echo "Replica cutover finished."
