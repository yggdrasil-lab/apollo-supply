#!/bin/bash

# Fail loudly. Without this a failed step is invisible and the deploy still
# reports success. It does not cover everything: `docker compose up -d` exits 0
# even when a container is created and then immediately dies.
set -e

# Load environment variables if .env exists
if [ -f .env ]; then
  source .env
fi

# slskd's download-layout options have no environment-variable equivalent, so
# config/slskd.yml is the only way to set them. docker-compose.yml mounts
# /opt/apollo-supply/slskd at /app, where slskd reads slskd.yml from, so the
# file has to be written into that host directory.
#
# The write goes through a helper container because the deploy runs on a
# self-hosted runner whose filesystem is its own container's, not the host's. A
# plain `install -o 1000 -g 1000 -m 644 config/slskd.yml
# /opt/apollo-supply/slskd/slskd.yml` therefore fails with "No such file or
# directory" - that path does not exist there - but the deploy carried on and
# reported success, leaving slskd running on the previous config. A bind mount's
# source is resolved by the daemon on the host, which is the only way to reach a
# real host path from the runner.
#
# This overwrites the host copy on every deploy - config/slskd.yml is the source
# of truth.
docker run --rm -i -v /opt/apollo-supply:/apollo-supply alpine sh -c "mkdir -p /apollo-supply/slskd && cat > /apollo-supply/slskd/slskd.yml && chown 1000:1000 /apollo-supply/slskd /apollo-supply/slskd/slskd.yml && chmod 755 /apollo-supply/slskd && chmod 644 /apollo-supply/slskd/slskd.yml" < config/slskd.yml

echo "Deploying Apollo Supply..."

echo "Stopping existing containers..."
docker compose down --remove-orphans

echo "Starting containers..."
docker compose up -d

echo "Deployment complete."
