#!/usr/bin/env bash

# Simple HTTP health server on port 8686
while true; do
  echo -e "HTTP/1.1 200 OK\r\n\r\nOK" | nc -l -p ${HEALTH_PORT:-8686} -q 1 || true
done
