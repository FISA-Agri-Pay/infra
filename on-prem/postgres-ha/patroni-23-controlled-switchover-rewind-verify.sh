#!/usr/bin/env bash
set -euo pipefail

# Run on either DB server after patroni-22.
# This performs a controlled switchover and verifies that the old leader returns
# as a streaming replica without manual reinit.
# It does not intentionally crash or power off a server.

CONFIG="${CONFIG:-/etc/patroni/patroni.yml}"
CLUSTER="${CLUSTER:-pg-cluster}"
WAIT_SECONDS="${WAIT_SECONDS:-180}"
SLEEP_SECONDS="${SLEEP_SECONDS:-5}"

wait_member_state() {
  local member="$1"
  local role_lc="$2"
  local state_lc="$3"
  local waited=0

  while (( waited <= WAIT_SECONDS )); do
    local matched
    matched="$(patronictl -c "${CONFIG}" list -f json | MEMBER="${member}" ROLE="${role_lc}" STATE="${state_lc}" python3 -c '
import json, sys, os
rows=json.load(sys.stdin)
member=os.environ["MEMBER"]
role=os.environ["ROLE"].lower()
state=os.environ["STATE"].lower()
for r in rows:
    if (r.get("Member") or "") == member:
        rr=(r.get("Role") or "").lower()
        ss=(r.get("State") or "").lower()
        if rr == role and ss == state:
            print("yes")
        else:
            print(f"no role={rr} state={ss}")
        break
else:
    print("no member-not-found")
')"
    patronictl -c "${CONFIG}" list
    if [[ "${matched}" == "yes" ]]; then
      return 0
    fi
    echo "Waiting for ${member} to become ${role_lc}/${state_lc}: ${matched}"
    sleep "${SLEEP_SECONDS}"
    waited=$((waited + SLEEP_SECONDS))
  done

  echo "ERROR: ${member} did not become ${role_lc}/${state_lc} within ${WAIT_SECONDS} seconds."
  exit 1
}

echo "[1/5] Current Patroni cluster state"
patronictl -c "${CONFIG}" list

CLUSTER_JSON="$(patronictl -c "${CONFIG}" list -f json)"
LEADER="$(python3 -c 'import json,sys; rows=json.loads(sys.argv[1]); print(next((r.get("Member","") for r in rows if r.get("Role") == "Leader"), ""))' "${CLUSTER_JSON}")"
CANDIDATE="$(python3 -c 'import json,sys; rows=json.loads(sys.argv[1]); print(next((r.get("Member","") for r in rows if r.get("Role") == "Replica" and (r.get("State") or "").lower() == "streaming"), ""))' "${CLUSTER_JSON}")"

if [[ -z "${LEADER}" || -z "${CANDIDATE}" ]]; then
  echo "ERROR: leader or streaming replica candidate not found."
  exit 1
fi

echo
echo "[2/5] Controlled switchover"
echo "Leader:    ${LEADER}"
echo "Candidate: ${CANDIDATE}"
patronictl -c "${CONFIG}" switchover "${CLUSTER}" \
  --leader "${LEADER}" \
  --candidate "${CANDIDATE}" \
  --force

echo
echo "[3/5] Verify new leader"
wait_member_state "${CANDIDATE}" "leader" "running"

echo
echo "[4/5] Verify old leader returned as streaming replica without reinit"
wait_member_state "${LEADER}" "replica" "streaming"

echo
echo "[5/5] Final cluster state"
patronictl -c "${CONFIG}" list

echo
echo "OK: controlled switchover completed and the old leader returned as streaming replica without manual reinit."
