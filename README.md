# Monitoring & Logging Infrastructure

Comprehensive monitoring and logging stack for VPS services using Prometheus, Grafana, Loki, and Promtail.

## Overview

This repository sets up a complete observability platform with:

- **Prometheus**: Metrics collection and storage
- **Grafana**: Unified visualization dashboard for metrics and logs
- **Loki**: Lightweight log aggregation
- **Promtail**: Log shipper for Docker containers
- **Node Exporter**: System-level metrics (CPU, RAM, disk, network)
- **cAdvisor**: Docker container metrics

## Architecture

### Services

```
┌─────────────┐  ┌──────────────┐  ┌──────────┐
│Node Exporter│  │   cAdvisor   │  │Prometheus│
└──────┬──────┘  └──────┬───────┘  └────┬─────┘
       │                │              │
       └────────────────┴──────────────┘
                        │
                  ┌─────▼─────┐
                  │ Prometheus │
                  │  Database  │
                  └─────┬──────┘
                        │
        ┌───────────────┼───────────────┐
        │               │               │
   ┌────▼────┐    ┌────▼────┐    ┌────▼────┐
   │ Grafana │    │  Loki   │    │Promtail │
   └─────────┘    └─────────┘    └────┬────┘
        │              ▲               │
        │              └───────────────┘
   nginx-proxy                    Docker logs
```

## Quick Start

### 1. Setup on Local Machine

```bash
cd /Users/antoine/Perso/monitoring
cp .env.dist .env
# Edit .env with your configuration
nano .env
```

### 2. Deploy to VPS

```bash
# Clone to VPS
ssh vps "mkdir -p /home/antoine/apps"
rsync -avz monitoring/ vps:/home/antoine/apps/monitoring/

# On VPS
cd /home/antoine/apps/monitoring
cp .env.dist .env
nano .env

# Start services
docker compose up -d

# Verify
docker compose ps
```

## Configuration

### Environment Variables (.env)

```bash
# Grafana web access via nginx-proxy
VIRTUAL_HOST=grafana.nguyenantoine.com
LETSENCRYPT_HOST=grafana.nguyenantoine.com
LETSENCRYPT_EMAIL=your-email@example.com

# Grafana admin credentials
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=your-secure-password

# Data retention
PROMETHEUS_RETENTION=15d      # How long to keep metrics
LOKI_RETENTION=7d             # How long to keep logs
```

### Prometheus Configuration

Edit `config/prometheus/prometheus.yml` to add scrape targets:

```yaml
scrape_configs:
  - job_name: 'my-service'
    static_configs:
      - targets: ['my-service:9100']
```

### Loki Configuration

Configured in `config/loki/loki-config.yml` for log storage and retention.

### Promtail Configuration

Automatically discovers and tails Docker container logs via docker daemon socket.

## Access

Once deployed on VPS:

- **Grafana**: https://grafana.nguyenantoine.com (requires SSL via nginx-proxy)
- **Prometheus**: http://vps:9090 (internal only)
- **Loki**: http://vps:3100 (internal only)

## Dashboards

Grafana dashboards are automatically provisioned. Available dashboards:

### Pre-configured
- System Overview (Node Exporter metrics)
- Docker Containers (cAdvisor metrics)
- Logs Browser (Loki logs)

### Future additions
- nginx-proxy metrics and access logs
- Nextcloud application metrics
- Database performance
- Custom service dashboards

## Data Storage

Persistent data is stored in `./data/`:

- `prometheus/`: Metrics (tsdb format)
- `grafana/`: Dashboards, datasources, preferences
- `loki/`: Logs (BoltDB with filesystem store)

These directories are gitignored and must be backed up separately.

## Docker Compose Commands

```bash
# Start all services
docker compose up -d

# View logs
docker compose logs -f grafana

# Stop services
docker compose down

# Restart specific service
docker compose restart prometheus

# Update images
./updateDockerImages.sh
```

## Monitoring Targets

### Currently Configured

1. **Prometheus Self**: Scrapes its own metrics
2. **Node Exporter**: System CPU, memory, disk, network
3. **cAdvisor**: Docker container resource usage

### Future Additions

1. **nginx-proxy**: HTTP metrics, request rates, response times
2. **Nextcloud**: Application metrics via PHP-FPM exporter
3. **MySQL/MariaDB**: Database queries, connections, performance
4. **Redis**: Cache hit/miss rates, memory usage
5. **Alertmanager**: Alert routing and notifications

## Log Queries

In Grafana Explore (with Loki datasource):

```logql
# All logs
{container=~".+"}

# Specific container
{container="nextcloud_app"}

# Logs containing "error"
{container=~".+"} |= "error"

# Logs from multiple containers
{container=~"nginx|nextcloud"}

# Parse JSON logs
{container="app"} | json
```

## Troubleshooting

### Prometheus targets down

```bash
# Check Prometheus targets
docker compose exec prometheus wget -qO- http://localhost:9090/api/v1/targets | jq

# Check network connectivity
docker compose exec prometheus ping node-exporter
```

### Loki not receiving logs

```bash
# Check Promtail logs
docker compose logs promtail

# Verify Docker socket mounting
docker compose exec promtail ls -la /var/run/docker.sock
```

### Grafana datasource issues

```bash
# Check datasource connectivity
docker compose logs grafana | grep datasource

# Verify internal DNS
docker compose exec grafana ping prometheus
docker compose exec grafana ping loki
```

### Disk space usage

```bash
# Check data directory size
du -sh data/

# Clean old data (if needed)
docker compose down
rm -rf data/prometheus/*
docker compose up -d
```

## Performance Notes

### Resource Usage

- **CPU**: ~0.5-1 core (all services combined)
- **Memory**: ~1-2 GB
  - Prometheus: 512 MB
  - Grafana: 256 MB
  - Loki: 256 MB
  - Others: 256 MB
- **Disk**: Grows with retention (5-10 GB for 7-15 days)

### Optimization Tips

1. Reduce scrape interval for less frequent updates
2. Adjust retention periods based on storage capacity
3. Use log sampling in Promtail for high-volume services
4. Configure Loki table retention to auto-delete old data

## Updates

```bash
# Update all Docker images to latest
./updateDockerImages.sh

# Or manually
docker compose pull
docker compose up -d
```

## Backups

Data in `./data/` should be backed up separately:

```bash
# Backup to external storage
rsync -avz /home/antoine/apps/monitoring/data/ backup/monitoring-data/
```

## Security Considerations

1. **Grafana Access**: Exposed via nginx-proxy with SSL
2. **Admin Password**: Change `GF_SECURITY_ADMIN_PASSWORD` in .env
3. **Prometheus/Loki**: Not exposed externally (internal network only)
4. **Docker Socket**: Mounted read-only in Promtail
5. **Network Isolation**: Uses internal `default` and external `reverse-proxy` networks

## Verification Steps

After deployment:

### 1. Container Status
```bash
docker compose ps
# All containers should show "Up" status
```

### 2. Prometheus Targets
```bash
# In browser or curl
curl http://vps:9090/api/v1/targets
# All targets should have state="up"
```

### 3. Grafana Access
- Navigate to https://grafana.nguyenantoine.com
- Login with configured credentials
- Check Connections → Data sources
- Both Prometheus and Loki should show "Connected"

### 4. Log Collection
- In Grafana Explore
- Select Loki datasource
- Query: `{container=~".+"}`
- Should see logs from all running containers

### 5. System Metrics
- Open Node Exporter Full dashboard
- Verify CPU, memory, disk, and network metrics

### 6. Container Metrics
- Open Docker Containers dashboard
- Should list all running containers with resource usage

## Maintenance

### Monthly Tasks
- [ ] Review data disk usage
- [ ] Verify all dashboards displaying correctly
- [ ] Check backup status

### Quarterly Tasks
- [ ] Update Docker images
- [ ] Review retention policies
- [ ] Clean up old dashboards or unused datasources

## Contributing

When adding new services to monitor:

1. Add scrape config to `config/prometheus/prometheus.yml`
2. Update Promtail config if adding custom log sources
3. Create dashboard in Grafana
4. Export dashboard JSON to version control
5. Document in README

## License

Same as parent organization

## Support

For issues or questions:
1. Check logs: `docker compose logs [service]`
2. Review troubleshooting section above
3. Check official documentation:
   - [Prometheus](https://prometheus.io/docs)
   - [Grafana](https://grafana.com/docs)
   - [Loki](https://grafana.com/docs/loki)
