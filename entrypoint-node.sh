#!/bin/sh
#
# Author/Maintainer: konrad@diva.exchange
#

# -e  Exit immediately if a simple command exits with a non-zero status
set -e

IP=${IP:-0.0.0.0}
PORT=${PORT:-10001}

su node -c "pm2-runtime start ecosystem.config.js"
