#!/usr/bin/env bash

qlog() {
  echo "[QuickPod] $*" | tee -a "${LOG_DIR:-/var/log/quickpod}/boot.log"
}

public_url() {
  local port="$1"
  local proto="${2:-http}"
  if [ -n "${PUBLIC_IPADDR:-}" ]; then
    echo "${proto}://${PUBLIC_IPADDR}:${port}"
  else
    echo "${proto}://localhost:${port}"
  fi
}
