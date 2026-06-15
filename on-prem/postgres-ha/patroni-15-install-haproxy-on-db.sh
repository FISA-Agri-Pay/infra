#!/usr/bin/env bash
set -euo pipefail

# Run on BOTH DB servers.
#
# This installs HAProxy and configures two local PostgreSQL entrypoints:
#   write endpoint: :5000 -> current Patroni primary
#   read endpoint:  :5001 -> current Patroni replica
#
# This does not create a single VIP. Because the two DB servers are on
# different subnets, Keepalived/VRRP is not a good default next step here.

WRITE_HOST="${WRITE_HOST:-192.168.100.23}"
READ_HOST="${READ_HOST:-10.30.4.11}"
CONFIG="/etc/haproxy/haproxy.cfg"
BACKUP="/etc/haproxy/haproxy.cfg.$(date +%Y%m%d%H%M%S).bak"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run with sudo/root."
  exit 1
fi

echo "[1/6] Install HAProxy if needed"
if ! command -v haproxy >/dev/null 2>&1; then
  apt-get update
  apt-get install -y haproxy
fi
haproxy -v

echo
echo "[2/6] Check local ports"
ss -ltnp | grep -E '(:5000|:5001|:7000)' && {
  echo "ERROR: one of ports 5000/5001/7000 is already in use."
  exit 1
} || true

echo
echo "[3/6] Backup existing HAProxy config"
if [[ -f "${CONFIG}" ]]; then
  cp -a "${CONFIG}" "${BACKUP}"
  echo "Backup: ${BACKUP}"
fi

echo
echo "[4/6] Write HAProxy config"
cat >"${CONFIG}" <<EOF
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

defaults
    log global
    mode tcp
    option tcplog
    timeout connect 5s
    timeout client  1m
    timeout server  1m

listen stats
    bind *:7000
    mode http
    stats enable
    stats uri /
    stats refresh 5s

listen pg_write
    bind *:5000
    mode tcp
    option httpchk GET /primary
    http-check expect status 200
    default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
    server postgresql-write ${WRITE_HOST}:5432 maxconn 200 check port 8008
    server postgresql-read  ${READ_HOST}:5432 maxconn 200 check port 8008

listen pg_read
    bind *:5001
    mode tcp
    option httpchk GET /replica
    http-check expect status 200
    default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
    server postgresql-write ${WRITE_HOST}:5432 maxconn 200 check port 8008
    server postgresql-read  ${READ_HOST}:5432 maxconn 200 check port 8008
EOF

echo
echo "[5/6] Validate and restart HAProxy"
haproxy -c -f "${CONFIG}"
systemctl enable haproxy
systemctl restart haproxy

echo
echo "[6/6] HAProxy status"
systemctl status haproxy --no-pager
ss -ltnp | grep -E '(:5000|:5001|:7000)' || true

echo
echo "HAProxy endpoints on this server:"
echo "  write: $(hostname -I | awk '{print $1}'):5000"
echo "  read:  $(hostname -I | awk '{print $1}'):5001"
echo "  stats: http://$(hostname -I | awk '{print $1}'):7000/"
