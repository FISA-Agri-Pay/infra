#!/usr/bin/env bash
set -euo pipefail

# Run on either DB server only AFTER patroni-09 verification looks healthy.
# This performs a controlled switchover from postgresql-write to postgresql-read.
#
# It is safer than killing the primary because Patroni coordinates the role change.

CONFIG="${CONFIG:-/etc/patroni/patroni.yml}"
CLUSTER="${CLUSTER:-pg-cluster}"
CURRENT_LEADER="${CURRENT_LEADER:-postgresql-write}"
CANDIDATE="${CANDIDATE:-postgresql-read}"

echo "[1/5] Current Patroni cluster state"
patronictl -c "${CONFIG}" list

echo
echo "[2/5] Confirm current leader and candidate"
echo "Cluster:        ${CLUSTER}"
echo "Current leader: ${CURRENT_LEADER}"
echo "Candidate:      ${CANDIDATE}"

echo
echo "[3/5] Running controlled switchover"
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
echo "Switchover test finished."
echo "Expected after this test:"
echo "  postgresql-read  = Leader"
echo "  postgresql-write = Replica"
