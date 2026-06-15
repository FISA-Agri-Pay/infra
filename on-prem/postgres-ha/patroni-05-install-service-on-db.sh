#!/usr/bin/env bash
set -euo pipefail

# Run on BOTH DB servers as root:
#   sudo bash patroni-05-install-service-on-db.sh
#
# This only installs/updates the Patroni systemd unit.
# It does not stop PostgreSQL and does not start Patroni.

CONFIG="${CONFIG:-/etc/patroni/patroni.yml}"
UNIT="/etc/systemd/system/patroni.service"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run with sudo/root."
  exit 1
fi

if [[ ! -f "${CONFIG}" ]]; then
  echo "Missing ${CONFIG}"
  exit 1
fi

command -v patroni >/dev/null

cat >"${UNIT}" <<EOF
[Unit]
Description=Patroni PostgreSQL HA manager
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=postgres
Group=postgres
ExecStart=/usr/bin/patroni ${CONFIG}
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=process
TimeoutSec=30
Restart=on-failure
RestartSec=5
LimitNOFILE=262144

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

echo "Installed ${UNIT}"
echo "Patroni service is not started yet."
systemctl status patroni --no-pager || true
