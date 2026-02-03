# Grafana Dashboards

Pre-built dashboards ready to import into Grafana.

## Available Dashboards

### 1. Quick Status (`quick-status.json`)
Overview of system and service health:
- Service status indicators (Prometheus, Node Exporter, cAdvisor)
- Current CPU and Memory usage gauges
- Number of running containers

**Best for**: Quick health check and status overview

### 2. System Overview (`system-overview.json`)
Detailed system metrics:
- CPU usage over time
- Memory usage over time
- Disk usage over time
- Network I/O (receive/transmit)

**Best for**: System performance analysis

### 3. Docker Containers (`docker-containers.json`)
Container resource monitoring:
- Count of running containers
- Memory usage per container
- CPU usage per container
- Network I/O per container

**Best for**: Container resource management and troubleshooting

### 4. Logs Browser (`logs-browser.json`)
Log aggregation and analysis:
- Log volume distribution by container
- Top 10 log producers
- Log volume trends
- Live log viewer with all container logs

**Best for**: Log searching and troubleshooting

## How to Import

### Method 1: Via Grafana UI
1. Go to **Dashboards** → **+ Create** → **Import**
2. Paste the dashboard JSON content
3. Select **Prometheus** (or **Loki** for logs dashboard) as datasource
4. Click **Import**

### Method 2: Via Dashboard File
1. Go to **Dashboards** → **+ Create** → **Import**
2. Click **Upload JSON file**
3. Select the dashboard JSON file
4. Click **Import**

### Method 3: API (Automated)
```bash
curl -X POST http://grafana:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_TOKEN" \
  -d @quick-status.json
```

## Customization

Each dashboard can be customized:
- Edit the JSON to modify queries
- Change time ranges
- Adjust thresholds and colors
- Add/remove panels

### Common Query Modifications

**For specific container:**
```
{container="nextcloud_app"}
```

**For specific error level:**
```
{container=~".+"} |= "error"
```

**For multiple containers:**
```
{container=~"nginx|nextcloud"}
```

## Notes

- Dashboards auto-refresh every 30 seconds for metrics
- Logs refresh every 5 seconds for latest logs
- Adjust refresh rates based on your needs
- Some metrics require cAdvisor and Node Exporter to be running
