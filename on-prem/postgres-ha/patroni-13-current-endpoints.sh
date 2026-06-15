#!/usr/bin/env bash
set -euo pipefail

# Run on either DB server.
# Prints the current write/read endpoints based on Patroni state.

CONFIG="${CONFIG:-/etc/patroni/patroni.yml}"
WRITE_HOST="${WRITE_HOST:-192.168.100.23}"
READ_HOST="${READ_HOST:-10.30.4.11}"
WRITE_NODE="${WRITE_NODE:-postgresql-write}"
READ_NODE="${READ_NODE:-postgresql-read}"

LEADER="$(patronictl -c "${CONFIG}" list -f json | python3 -c 'import json, sys; rows=json.load(sys.stdin); print(next((r.get("Member", "") for r in rows if r.get("Role") == "Leader"), ""))')"

case "${LEADER}" in
  "${WRITE_NODE}")
    PRIMARY_HOST="${WRITE_HOST}"
    REPLICA_HOST="${READ_HOST}"
    ;;
  "${READ_NODE}")
    PRIMARY_HOST="${READ_HOST}"
    REPLICA_HOST="${WRITE_HOST}"
    ;;
  *)
    echo "ERROR: unknown or missing leader: ${LEADER}"
    exit 1
    ;;
esac

echo "Current PostgreSQL endpoints:"
echo "  write/primary: ${PRIMARY_HOST}:5432"
echo "  read/replica:  ${REPLICA_HOST}:5432"
echo
echo "Patroni REST endpoints:"
echo "  postgresql-write: http://${WRITE_HOST}:8008"
echo "  postgresql-read:  http://${READ_HOST}:8008"
