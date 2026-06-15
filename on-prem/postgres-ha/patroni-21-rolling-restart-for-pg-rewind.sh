#!/usr/bin/env bash
set -euo pipefail

# Run on either DB server after patroni-20-enable-pg-rewind-config.sh.
# This applies wal_log_hints=on with a controlled rolling restart:
#   1. restart a streaming replica
#   2. switchover to that replica
#   3. restart the old leader after it becomes replica
#
# This changes the current leader. If you want to switch back afterward, run
# patroni-10/11 style switchover manually or set SWITCH_BACK=true.

CONFIG="${CONFIG:-/etc/patroni/patroni.yml}"
CLUSTER="${CLUSTER:-pg-cluster}"
SWITCH_BACK="${SWITCH_BACK:-false}"
WAIT_SECONDS="${WAIT_SECONDS:-180}"
SLEEP_SECONDS="${SLEEP_SECONDS:-5}"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "ERROR: missing command: $1"; exit 1; }
}

json_query() {
  python3 -c "$1"
}

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

need_cmd patronictl
need_cmd python3

echo "[1/8] Verify dynamic config"
DYNAMIC_CONFIG="$(patronictl -c "${CONFIG}" show-config)"
echo "${DYNAMIC_CONFIG}"
if ! grep -Eq "use_pg_rewind:[[:space:]]*true" <<< "${DYNAMIC_CONFIG}"; then
  echo "ERROR: Patroni DCS does not show use_pg_rewind: true. Run patroni-20 first."
  exit 1
fi
if ! grep -Eiq "wal_log_hints:[[:space:]]*['\"]?(on|true)['\"]?" <<< "${DYNAMIC_CONFIG}"; then
  echo "ERROR: Patroni DCS does not show wal_log_hints: on/true. Run patroni-20 first."
  exit 1
fi

echo
echo "[2/8] Detect current leader and streaming replica candidate"
CLUSTER_JSON="$(patronictl -c "${CONFIG}" list -f json)"
LEADER="$(python3 -c 'import json,sys; rows=json.loads(sys.argv[1]); print(next((r.get("Member","") for r in rows if r.get("Role") == "Leader"), ""))' "${CLUSTER_JSON}")"
CANDIDATE="$(python3 -c 'import json,sys; rows=json.loads(sys.argv[1]); print(next((r.get("Member","") for r in rows if r.get("Role") == "Replica" and (r.get("State") or "").lower() == "streaming"), ""))' "${CLUSTER_JSON}")"

if [[ -z "${LEADER}" || -z "${CANDIDATE}" ]]; then
  echo "ERROR: leader or streaming replica candidate not found."
  patronictl -c "${CONFIG}" list
  exit 1
fi

echo "Current leader: ${LEADER}"
echo "Restart/switchover candidate: ${CANDIDATE}"

echo
echo "[3/8] Restart replica first to apply wal_log_hints=on"
patronictl -c "${CONFIG}" restart "${CLUSTER}" "${CANDIDATE}" --force
wait_member_state "${CANDIDATE}" "replica" "streaming"

echo
echo "[4/8] Controlled switchover to restarted replica"
patronictl -c "${CONFIG}" switchover "${CLUSTER}" \
  --leader "${LEADER}" \
  --candidate "${CANDIDATE}" \
  --force
wait_member_state "${CANDIDATE}" "leader" "running"

echo
echo "[5/8] Wait for old leader to follow the new leader"
wait_member_state "${LEADER}" "replica" "streaming"

echo
echo "[6/8] Restart old leader, now replica, to apply wal_log_hints=on"
patronictl -c "${CONFIG}" restart "${CLUSTER}" "${LEADER}" --force
wait_member_state "${LEADER}" "replica" "streaming"

if [[ "${SWITCH_BACK}" == "true" ]]; then
  echo
  echo "[7/8] SWITCH_BACK=true, switching leader back to ${LEADER}"
  patronictl -c "${CONFIG}" switchover "${CLUSTER}" \
    --leader "${CANDIDATE}" \
    --candidate "${LEADER}" \
    --force
  wait_member_state "${LEADER}" "leader" "running"
  wait_member_state "${CANDIDATE}" "replica" "streaming"
else
  echo
  echo "[7/8] SWITCH_BACK=false, keeping current leader as ${CANDIDATE}"
fi

echo
echo "[8/8] Final Patroni cluster state"
patronictl -c "${CONFIG}" list

echo
echo "OK: rolling restart finished. Run patroni-22-verify-pg-rewind-ready.sh on either DB server."
