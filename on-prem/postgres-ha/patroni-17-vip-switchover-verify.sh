#!/usr/bin/env bash
set -euo pipefail

# Run on either DB server after pfSense HAProxy VIP routing works.
# This verifies:
#   VIP:5432 -> current primary
#   VIP:5433 -> current replica
# then performs a controlled Patroni switchover and verifies the VIPs again.

CONFIG="${CONFIG:-/etc/patroni/patroni.yml}"
CLUSTER="${CLUSTER:-pg-cluster}"
VIP="${VIP:-192.0.2.12}"
DB_NAME="${DB_NAME:-postgres}"
DB_USER="${DB_USER:-postgres}"
: "${DB_PASSWORD:?Set DB_PASSWORD before running this verification.}"

export PGPASSWORD="${DB_PASSWORD}"

check_vip() {
  local phase="$1"
  echo
  echo "[$phase] Checking VIP write endpoint ${VIP}:5432"
  local write_recovery
  write_recovery="$(psql -h "${VIP}" -p 5432 -U "${DB_USER}" -d "${DB_NAME}" -Atc "select pg_is_in_recovery();")"
  echo "VIP:5432 pg_is_in_recovery=${write_recovery}"
  if [[ "${write_recovery}" != "f" ]]; then
    echo "ERROR: VIP write endpoint is not pointing to primary."
    exit 1
  fi

  echo
  echo "[$phase] Checking VIP read endpoint ${VIP}:5433"
  local read_recovery
  read_recovery="$(psql -h "${VIP}" -p 5433 -U "${DB_USER}" -d "${DB_NAME}" -Atc "select pg_is_in_recovery();")"
  echo "VIP:5433 pg_is_in_recovery=${read_recovery}"
  if [[ "${read_recovery}" != "t" ]]; then
    echo "ERROR: VIP read endpoint is not pointing to replica."
    exit 1
  fi
}

echo "[1/6] Current Patroni cluster state"
patronictl -c "${CONFIG}" list

echo
echo "[2/6] Detect leader and replica candidate"
LEADER="$(patronictl -c "${CONFIG}" list -f json | python3 -c 'import json, sys; rows=json.load(sys.stdin); print(next((r.get("Member", "") for r in rows if r.get("Role") == "Leader"), ""))')"
CANDIDATE="$(patronictl -c "${CONFIG}" list -f json | python3 -c 'import json, sys; rows=json.load(sys.stdin); print(next((r.get("Member", "") for r in rows if r.get("Role") == "Replica"), ""))')"

if [[ -z "${LEADER}" || -z "${CANDIDATE}" ]]; then
  echo "ERROR: leader or replica candidate not found."
  exit 1
fi

echo "Current leader: ${LEADER}"
echo "Candidate:      ${CANDIDATE}"

echo
echo "[3/6] Verify VIP routing before switchover"
check_vip "before switchover"

echo
echo "[4/6] Controlled Patroni switchover"
patronictl -c "${CONFIG}" switchover "${CLUSTER}" \
  --leader "${LEADER}" \
  --candidate "${CANDIDATE}" \
  --force

echo
echo "[5/6] Wait for HAProxy health checks to settle"
sleep 10
patronictl -c "${CONFIG}" list

echo
echo "[6/6] Verify VIP routing after switchover"
check_vip "after switchover"

echo
echo "OK: Patroni switchover and pfSense VIP routing both work."
