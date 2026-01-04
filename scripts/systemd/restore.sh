#!/bin/bash

# Define container names
VPN_CONTAINER="gluetun"
DEPENDENT_CONTAINERS=("qbittorrent" "sabnzbd")

echo "Starting Apollo Supply Resume..."

# 1. Start the VPN Container
echo "Starting $VPN_CONTAINER..."
/usr/bin/docker start $VPN_CONTAINER

# 2. Wait for GlueTun to be Healthy
echo "Waiting for $VPN_CONTAINER to be healthy..."
MAX_RETRIES=60
COUNT=0

while [ $COUNT -lt $MAX_RETRIES ]; do
    HEALTH_STATUS=$(/usr/bin/docker inspect --format '{{.State.Health.Status}}' $VPN_CONTAINER 2>/dev/null)
    
    if [ "$HEALTH_STATUS" == "healthy" ]; then
        echo "$VPN_CONTAINER is healthy."
        break
    fi
    
    if [ "$HEALTH_STATUS" == "unhealthy" ]; then
        echo "$VPN_CONTAINER is unhealthy! Aborting start of dependents."
        exit 1
    fi

    echo "Status: $HEALTH_STATUS. Waiting..."
    sleep 2
    COUNT=$((COUNT+1))
done

if [ $COUNT -ge $MAX_RETRIES ]; then
    echo "Timed out waiting for $VPN_CONTAINER to be healthy."
    exit 1
fi

# 3. Start Dependent Containers
for container in "${DEPENDENT_CONTAINERS[@]}"; do
    echo "Starting $container..."
    /usr/bin/docker start $container
done

echo "Resume complete."
