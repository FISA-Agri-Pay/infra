#!/usr/bin/env bash
set -euo pipefail

# Run on either DB server when patronictl shows a replica as stopped/unknown
# after a switchover.
#
# This is expected in this lab setup because pg_rewind is disabled:
#   wal_log_hints=off
#   data_checksums=off
#   use_pg_rewind=false
#
# WARNING: Patroni reinit recreates the selected replica from the current leader.
# Do not run this against the current leader.

CONFIG="${CONFIG:-/etc/patroni/patroni.yml}"
CLUSTER="${CLUSTER:-pg-cluster}"

echo "[1/5] Current Patroni cluster state"
patronictl -c "${CONFIG}" list

echo
echo "[2/5] Detect stopped replicas"
STOPPED_REPLICAS="$(
  patronictl -c "${CONFIG}" list -f json |
    python3 -c 'import json, sys
rows=json.load(sys.stdin)
for r in rows:
    role=(r.get("Role") or "").lower()
    state=(r.get("State") or "").lower()
    member=r.get("Member") or ""
    if role == "replica" and state != "streaming":
        print(member)'
)"

if [[ -z "${STOPPED_REPLICAS}" ]]; then
  echo "No stopped/non-streaming replicas found."
  exit 0
fi

echo "${STOPPED_REPLICAS}"

echo
echo "[3/5] Reinitialize stopped replicas from current leader"
while IFS= read -r MEMBER; do
  [[ -z "${MEMBER}" ]] && continue
  echo
  echo "Reinitializing replica: ${MEMBER}"
  patronictl -c "${CONFIG}" reinit "${CLUSTER}" "${MEMBER}" --force
done <<< "${STOPPED_REPLICAS}"

echo
echo "[4/5] Wait for replicas to become streaming"
for i in {1..60}; do
  NON_STREAMING_COUNT="$(
    patronictl -c "${CONFIG}" list -f json |
      python3 -c 'import json, sys
rows=json.load(sys.stdin)
count=0
for r in rows:
    role=(r.get("Role") or "").lower()
    state=(r.get("State") or "").lower()
    if role == "replica" and state != "streaming":
        count += 1
print(count)'
  )"
  patronictl -c "${CONFIG}" list
  if [[ "${NON_STREAMING_COUNT}" == "0" ]]; then
    break
  fi
  sleep 5
  if [[ "${i}" -eq 60 ]]; then
    echo "ERROR: replica did not become streaming in time."
    exit 1
  fi
done

echo
echo "[5/5] Final cluster state"
patronictl -c "${CONFIG}" list

echo
echo "OK: all replicas are streaming."
