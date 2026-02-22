# Monitoring Infrastructure

Comprehensive metrics monitoring stack for VPS services using Prometheus, Grafana, Node Exporter, and cAdvisor.

## Overview

This repository sets up a complete observability platform with:

- **Prometheus**: Metrics collection and storage
- **Grafana**: Unified visualization dashboard for metrics
- **Node Exporter**: System-level metrics (CPU, RAM, disk, network)
- **cAdvisor**: Docker container metrics

> **Note**: Loki (log aggregation) is currently disabled. To re-enable, uncomment services in `docker-compose.yml`.

## Architecture

### Services

```
┌─────────────┐  ┌──────────────┐
│Node Exporter│  │   cAdvisor   │
└──────┬──────┘  └──────┬───────┘
       │                │
       └────────────────┴──────────────┐
                        │
                  ┌─────▼─────┐
                  │ Prometheus │
                  │  Database  │
                  └─────┬──────┘
                        │
                   ┌────▼────┐
                   │ Grafana  │
                   └──────────┘
                        │
                   nginx-proxy
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
```

### Prometheus Configuration

Edit `config/prometheus/prometheus.yml` to add scrape targets:

```yaml
scrape_configs:
  - job_name: 'my-service'
    static_configs:
      - targets: ['my-service:9100']
```


## Access

Once deployed on VPS:

- **Grafana**: https://grafana.nguyenantoine.com (requires SSL via nginx-proxy)
- **Prometheus**: http://vps:9090 (internal only)

## Dashboards

Grafana dashboards are automatically provisioned. Available dashboards:

### Pre-configured
- System Overview (Node Exporter metrics)
- Docker Containers (cAdvisor metrics)

### Future additions
- nginx-proxy metrics and access logs
- Nextcloud application metrics
- Database performance
- Custom service dashboards

## Data Storage

Persistent data is stored in `./data/`:

- `prometheus/`: Metrics (tsdb format)
- `grafana/`: Dashboards, datasources, preferences

These directories are gitignored and must be backed up separately.

## Re-enabling Loki (Log Aggregation)

Loki is currently disabled to reduce storage and resource usage. If you need log aggregation in the future:

### 1. Uncomment Services in docker-compose.yml

```bash
# Uncomment these sections in docker-compose.yml:
# - loki service (lines 44-56)
# - promtail service (lines 58-71)
# - loki_data volume (lines 124-125)
# - Add "- loki" back to grafana's depends_on (line 24)
```

### 2. Restart Services

```bash
docker compose down
docker compose up -d
```

### 3. Add Loki Datasource in Grafana

- Navigate to Grafana → Connections → Data sources
- Add new datasource: Loki
- URL: `http://loki:3100`

### 4. Verify Logs Are Collected

```bash
# Check Promtail is collecting logs
docker compose logs promtail | head -20
```

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

## Troubleshooting

### Prometheus targets down

```bash
# Check Prometheus targets
docker compose exec prometheus wget -qO- http://localhost:9090/api/v1/targets | jq

# Check network connectivity
docker compose exec prometheus ping node-exporter
```

### Grafana datasource issues

```bash
# Check datasource connectivity
docker compose logs grafana | grep datasource

# Verify internal DNS
docker compose exec grafana ping prometheus
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

- **CPU**: ~0.5 cores (all services combined)
- **Memory**: ~1 GB
  - Prometheus: 512 MB
  - Grafana: 256 MB
  - Others: 256 MB
- **Disk**: Grows with retention (~5 GB for 15 days)

### Optimization Tips

1. Reduce scrape interval for less frequent updates
2. Adjust Prometheus retention periods based on storage capacity

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
3. **Prometheus**: Not exposed externally (internal network only)
4. **Network Isolation**: Uses internal `default` and external `reverse-proxy` networks

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
- Prometheus should show "Connected"

### 4. System Metrics
- Open Node Exporter Full dashboard
- Verify CPU, memory, disk, and network metrics

### 5. Container Metrics
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
