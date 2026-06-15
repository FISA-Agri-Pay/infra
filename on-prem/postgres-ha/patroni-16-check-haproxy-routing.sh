#!/usr/bin/env bash
set -euo pipefail

# Run on either DB server after HAProxy is installed.
# You can override HAPROXY_HOST to test the other HAProxy instance.
#
# Example:
#   HAPROXY_HOST=192.168.100.23 bash patroni-16-check-haproxy-routing.sh
#   HAPROXY_HOST=10.30.4.11 bash patroni-16-check-haproxy-routing.sh

HAPROXY_HOST="${HAPROXY_HOST:-127.0.0.1}"
DB_NAME="${DB_NAME:-postgres}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-postgres}"

export PGPASSWORD="${DB_PASSWORD}"

echo "[1/5] HAProxy port checks on ${HAPROXY_HOST}"
nc -zv "${HAPROXY_HOST}" 5000
nc -zv "${HAPROXY_HOST}" 5001

echo
echo "[2/5] Write endpoint role check (:5000)"
psql -h "${HAPROXY_HOST}" -p 5000 -U "${DB_USER}" -d "${DB_NAME}" -Atc \
  "select 'write_endpoint_in_recovery=' || pg_is_in_recovery();"

echo
echo "[3/5] Read endpoint role check (:5001)"
psql -h "${HAPROXY_HOST}" -p 5001 -U "${DB_USER}" -d "${DB_NAME}" -Atc \
  "select 'read_endpoint_in_recovery=' || pg_is_in_recovery();"

echo
echo "[4/5] Write through HAProxy write endpoint"
MARKER="haproxy-test-$(date +%Y%m%d%H%M%S)"
psql -h "${HAPROXY_HOST}" -p 5000 -U "${DB_USER}" -d "${DB_NAME}" -v ON_ERROR_STOP=1 <<SQL
create table if not exists public.haproxy_ha_test (
  id bigserial primary key,
  marker text not null,
  created_at timestamptz not null default now()
);
insert into public.haproxy_ha_test (marker) values ('${MARKER}');
SQL

echo
echo "[5/5] Read through HAProxy read endpoint"
for i in {1..30}; do
  COUNT="$(psql -h "${HAPROXY_HOST}" -p 5001 -U "${DB_USER}" -d "${DB_NAME}" -Atc "select count(*) from public.haproxy_ha_test where marker='${MARKER}';")"
  if [[ "${COUNT}" == "1" ]]; then
    echo "OK: HAProxy write/read routing works. marker=${MARKER}"
    exit 0
  fi
  sleep 1
done

echo "ERROR: row written through :5000 was not visible through :5001 within 30 seconds."
exit 1
