#!/usr/bin/env bash
set -euo pipefail

# Run on BOTH DB servers.
# It makes replication pg_hba rules symmetric, so either node can become
# leader and accept pg_basebackup/streaming replication from the other node.

HBA_FILE="${HBA_FILE:-/etc/postgresql/16/main/pg_hba.conf}"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run with sudo/root."
  exit 1
fi

if [[ ! -f "${HBA_FILE}" ]]; then
  echo "Missing ${HBA_FILE}"
  exit 1
fi

BACKUP="${HBA_FILE}.$(date +%Y%m%d%H%M%S).bak"
cp -a "${HBA_FILE}" "${BACKUP}"
echo "Backup: ${BACKUP}"

add_line() {
  local line="$1"
  if grep -Fqx "${line}" "${HBA_FILE}"; then
    echo "Already present: ${line}"
  else
    echo "${line}" >> "${HBA_FILE}"
    echo "Added: ${line}"
  fi
}

cat >> "${HBA_FILE}" <<'EOF_MARKER'

# Patroni replication rules
EOF_MARKER

add_line "host    replication     repl_user       192.0.2.23/32       scram-sha-256"
add_line "host    replication     repl_user       198.51.100.11/32           scram-sha-256"
add_line "host    replication     repl_user       192.0.2.0/24        scram-sha-256"
add_line "host    replication     repl_user       198.51.100.0/24            scram-sha-256"

chown postgres:postgres "${HBA_FILE}"
chmod 0640 "${HBA_FILE}"

echo
echo "Reloading PostgreSQL configuration if PostgreSQL is running..."
if sudo -u postgres psql -Atc "select 1" >/dev/null 2>&1; then
  sudo -u postgres psql -c "select pg_reload_conf();"
else
  echo "PostgreSQL is not accepting local SQL connections on this node. Skipping reload."
fi

echo
echo "Current Patroni/PostgreSQL state:"
systemctl is-active patroni || true
sudo -u postgres psql -Atc "select 'pg_is_in_recovery=' || pg_is_in_recovery();" 2>/dev/null || true

echo
echo "Done."
