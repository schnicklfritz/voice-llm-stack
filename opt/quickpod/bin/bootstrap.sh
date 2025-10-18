#!/usr/bin/env bash
set -Eeuo pipefail

source /opt/quickpod/bin/common.sh

qlog "Starting bootstrap..."

# Setup SSH if keys provided
if [ -n "${SSH_PUBLIC_KEY:-}" ]; then
  qlog "Setting up SSH access..."
  mkdir -p /root/.ssh
  echo "$SSH_PUBLIC_KEY" > /root/.ssh/authorized_keys
  chmod 700 /root/.ssh
  chmod 600 /root/.ssh/authorized_keys
  /usr/sbin/sshd -D &
  qlog "SSH daemon started"
fi

# Start health check server
bash /opt/quickpod/bin/start-health.sh &

qlog "Bootstrap complete"
