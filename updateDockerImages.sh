#!/bin/bash
set -e

echo "Updating Docker images for monitoring stack..."
echo ""

# Stop and remove containers
echo "Stopping services..."
docker compose down

# Pull latest images
echo "Pulling latest images..."
docker compose pull

# Start services
echo "Starting services..."
docker compose up -d

echo ""
echo "Update completed successfully."
echo ""
echo "To view status:"
echo "  docker compose ps"
echo ""
echo "To view logs:"
echo "  docker compose logs -f"
