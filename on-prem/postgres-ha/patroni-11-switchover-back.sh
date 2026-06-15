#!/usr/bin/env bash
set -euo pipefail

# Run on either DB server after patroni-10-switchover-test.sh if you want
# to move the leader role back to postgresql-write.

CONFIG="${CONFIG:-/etc/patroni/patroni.yml}"
CLUSTER="${CLUSTER:-pg-cluster}"
CURRENT_LEADER="${CURRENT_LEADER:-postgresql-read}"
CANDIDATE="${CANDIDATE:-postgresql-write}"

echo "[1/5] Current Patroni cluster state"
patronictl -c "${CONFIG}" list

echo
echo "[2/5] Confirm current leader and candidate"
echo "Cluster:        ${CLUSTER}"
echo "Current leader: ${CURRENT_LEADER}"
echo "Candidate:      ${CANDIDATE}"

echo
echo "[3/5] Running controlled switchover back"
patronictl -c "${CONFIG}" switchover "${CLUSTER}" \
  --leader "${CURRENT_LEADER}" \
  --candidate "${CANDIDATE}" \
  --force

echo
echo "[4/5] Waiting briefly"
sleep 5

echo
echo "[5/5] New Patroni cluster state"
patronictl -c "${CONFIG}" list

echo
echo "Switchover-back finished."
echo "Expected after this test:"
echo "  postgresql-write = Leader"
echo "  postgresql-read  = Replica"
