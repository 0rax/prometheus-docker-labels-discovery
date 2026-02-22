#!/bin/sh
set -eu
PROMETHEUS_CONFIG_FILE_PATH=${PROMETHEUS_CONFIG_FILE_PATH?}

echo "[]" > "${PROMETHEUS_CONFIG_FILE_PATH}"

if [ $# -gt 0 ]; then
    exec "$@"
fi
