#!/bin/bash

# Load environment variables if .env exists
if [ -f .env ]; then
  source .env
fi

# slskd's download-layout options have no environment-variable equivalent, so
# config/slskd.yml is the only way to set them. It is installed here rather than
# bind-mounted: a mount sourced from this checkout is resolved inside the
# runner's own filesystem, which the Docker daemon cannot see, so the daemon
# creates an empty directory at that path and the container fails to start.
# The target below is the directory docker-compose.yml mounts at /app, where
# slskd reads slskd.yml from. This overwrites the host copy on every deploy -
# config/slskd.yml is the source of truth.
install -o 1000 -g 1000 -m 644 config/slskd.yml /opt/apollo-supply/slskd/slskd.yml

echo "Deploying Apollo Supply..."

echo "Stopping existing containers..."
docker compose down --remove-orphans

echo "Starting containers..."
docker compose up -d

echo "Deployment complete."
