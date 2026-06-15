#!/usr/bin/env bash
set -euo pipefail

# Run on each DB server after copying the matching YAML file.
# Usage:
#   sudo bash patroni-03-prepare-config-on-db.sh /path/to/patroni-write.yml
#   sudo bash patroni-03-prepare-config-on-db.sh /path/to/patroni-read.yml

SOURCE_CONFIG="${1:?Usage: sudo bash patroni-03-prepare-config-on-db.sh /path/to/patroni.yml}"
TARGET_DIR="/etc/patroni"
TARGET_CONFIG="${TARGET_DIR}/patroni.yml"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run with sudo/root."
  exit 1
fi

if [[ ! -f "${SOURCE_CONFIG}" ]]; then
  echo "Config file not found: ${SOURCE_CONFIG}"
  exit 1
fi

install -d -m 0750 -o postgres -g postgres "${TARGET_DIR}"
install -m 0640 -o postgres -g postgres "${SOURCE_CONFIG}" "${TARGET_CONFIG}"

echo "Installed ${TARGET_CONFIG}"
echo
echo "Validating patroni command availability..."
command -v patroni
command -v patronictl
echo
echo "Do NOT stop PostgreSQL yet unless you are ready for Patroni cutover."
echo "Next validation command:"
echo "  sudo -u postgres patroni ${TARGET_CONFIG}"
echo
echo "Use the command above only for a foreground dry start attempt during the cutover step."
