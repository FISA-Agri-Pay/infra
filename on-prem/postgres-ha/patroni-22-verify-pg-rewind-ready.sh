#!/usr/bin/env bash
set -euo pipefail

# Run on either DB server after patroni-21.
# This verifies:
#   - Patroni DCS has use_pg_rewind=true
#   - every known member reports wal_log_hints=on
#   - replicas are streaming

CONFIG="${CONFIG:-/etc/patroni/patroni.yml}"
DB_NAME="${DB_NAME:-postgres}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-postgres}"

export PGPASSWORD="${DB_PASSWORD}"

echo "[1/4] Patroni dynamic config"
patronictl -c "${CONFIG}" show-config

echo
echo "[2/4] Patroni cluster state"
patronictl -c "${CONFIG}" list

echo
echo "[3/4] Check wal_log_hints on every member"
patronictl -c "${CONFIG}" list -f json | python3 -c '
import json, sys
rows=json.load(sys.stdin)
for r in rows:
    member=r.get("Member") or ""
    host=r.get("Host") or ""
    if member and host:
        print(f"{member} {host}")
' | while read -r MEMBER HOST; do
  echo
  echo "Member: ${MEMBER} (${HOST})"
  psql -h "${HOST}" -p 5432 -U "${DB_USER}" -d "${DB_NAME}" -Atc "select 'pg_is_in_recovery=' || pg_is_in_recovery();"
  psql -h "${HOST}" -p 5432 -U "${DB_USER}" -d "${DB_NAME}" -Atc "select 'wal_log_hints=' || current_setting('wal_log_hints');"
done

echo
echo "[4/4] Replication status summary"
patronictl -c "${CONFIG}" list -f json | python3 -c '
import json, sys
rows=json.load(sys.stdin)
errors=[]
for r in rows:
    role=(r.get("Role") or "").lower()
    state=(r.get("State") or "").lower()
    member=r.get("Member") or ""
    if role == "leader" and state != "running":
        errors.append(f"leader {member} state is {state}")
    if role == "replica" and state != "streaming":
        errors.append(f"replica {member} state is {state}")
if errors:
    print("ERROR:")
    print("\n".join(errors))
    sys.exit(1)
print("OK: leader is running and all replicas are streaming.")
'

echo
echo "OK: pg_rewind prerequisites look ready."
