#!/bin/bash

# Load environment variables if .env exists
if [ -f .env ]; then
  source .env
fi

echo "Deploying Apollo Supply..."

echo "Stopping existing containers..."
docker compose down --remove-orphans

echo "Starting containers..."
docker compose up -d

echo "Deployment complete."
