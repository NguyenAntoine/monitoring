#!/bin/bash
set -e

echo "Updating Docker images for monitoring stack..."
echo ""

# Pull latest images
echo "Pulling latest images..."
docker compose pull

echo ""
echo "Images updated successfully."
echo ""
echo "To apply updates, run:"
echo "  docker compose up -d"
echo ""
echo "To view changes:"
echo "  docker compose ps"
