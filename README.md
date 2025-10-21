# TraeSentinel: Automated Reverse Proxy + Monitoring Stack

A self-contained, modular DevOps stack featuring:
- 🧬 **Traefik v3** reverse proxy with automatic SSL (ACME)
- ☁️ DNS automation via **Cloudflare** or **Namecheap**
- 📊 Full observability: **Grafana**, **Prometheus**, **Node Exporter**, **cAdvisor**
- 🔧 Managed by a single smart script — `deploy.sh`

Built for **Ubuntu Server 24.04 LTS** and **Docker Compose**.

---

## 🚀 Quick Start

```bash
git clone https://github.com/Anganba/TraeSentinel.git
cd TraeSentinel
sudo docker network create frontend
sudo docker network create monitoring
sudo chmod +x deploy.sh
sudo ./deploy.sh up cloudflare
```

> Default DNS provider: Cloudflare  
> To switch: `sudo ./deploy.sh up namecheap`

---

## 🌐 Services Overview

| Service | URL Example | Description |
|----------|-------------|--------------|
| Traefik Dashboard | https://traefik.anganba.me | Reverse proxy routing & SSL management |
| Grafana | https://mon.anganba.me | Visual monitoring & analytics UI |
| Portainer | https://portainer.anganba.me | Docker web management interface |
| Prometheus | *internal only* | Metrics collector |
| Node Exporter / cAdvisor | *internal only* | System & container-level metrics |

All services are automatically networked and secured through Traefik.

---

## 📦 Deployment Script

`deploy.sh` provides lifecycle management for the full TraeSentinel stack:

```bash
sudo ./deploy.sh up        # Start the full stack
sudo ./deploy.sh down      # Stop all containers
sudo ./deploy.sh restart   # Restart everything
sudo ./deploy.sh status    # Show container health summary
```

### Script Behavior
- Detects **Docker**, **Docker Compose**, or **Podman Compose** automatically.
- Loads each stack from `stack.list` dynamically.
- Supports provider-specific `.env` files for Cloudflare and Namecheap.
- Prints colored, timestamped logs for clarity.

---

## ⚙️ Configuration

### DNS Provider Environment Files

#### **Cloudflare** (`Traefik/.env.cloudflare`)
```env
PROVIDER=cloudflare
ACME_EMAIL=info@yourdomain
CF_DNS_API_TOKEN=your_cloudflare_token
```

#### **Namecheap** (`Traefik/.env.namecheap`)
```env
PROVIDER=namecheap
ACME_EMAIL=info@yourdomain
NAMECHEAP_API_USER=your_user
NAMECHEAP_API_KEY=your_key
NAMECHEAP_API_URL=https://api.namecheap.com/xml.response
```

Each `.env` file defines your ACME certificate resolver and API credentials.

---

## 🔍 Monitoring Stack

The monitoring suite lives entirely in the private `monitoring` Docker network.

### Prometheus
- Collects metrics from Traefik, cAdvisor, Node Exporter, and others.
- **No public ports exposed**.
- Scrape configuration examples:

```yaml
scrape_configs:
  - job_name: "traefik"
    static_configs:
      - targets: ["traefik:8080"]

  - job_name: "node_exporter"
    static_configs:
      - targets: ["node-exporter:9100"]

  - job_name: "cadvisor"
    static_configs:
      - targets: ["cadvisor:8080"]
```

### Grafana
- Connects internally to Prometheus: `http://prometheus:9090`
- Default admin credentials:
  ```bash
  admin / changeme
  ```
- Accessible at `https://mon.anganba.me`

### Node Exporter
- Provides OS-level metrics (CPU, memory, disks).
- Runs in `host` PID mode for system visibility.

### cAdvisor
- Collects container-level metrics directly from Docker.
- Accessible internally via `cadvisor:8080/metrics`.

---

## 🛠️ Traefik Configuration

Traefik handles:
- Dynamic reverse proxy routing
- Automatic Let's Encrypt or Cloudflare SSL certificates
- Middleware for HTTPS redirection and authentication

**Entrypoints:**
```yaml
--entrypoints.web.address=:80
--entrypoints.websecure.address=:443
--entrypoints.metrics.address=:8080
```

**Metrics:**
```yaml
--metrics.prometheus=true
--metrics.prometheus.entryPoint=metrics
```

**Routers & Services Example (Grafana)**
```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.grafana.rule=Host(`mon.anganba.me`)"
  - "traefik.http.routers.grafana.entrypoints=websecure"
  - "traefik.http.routers.grafana.tls.certresolver=${PROVIDER}"
  - "traefik.http.services.grafana.loadbalancer.server.port=3000"
```

---

## 🛡️ Security Model

- Traefik is the only publicly exposed entry point (ports 80 & 443).
- Prometheus, Node Exporter, and cAdvisor remain internal.
- HTTPS enforced for all external routes.
- Cloudflare or Namecheap API-driven SSL (ACME DNS-01 challenge).

### Optional Hardening
- Restrict access to dashboards using basic auth:
  ```yaml
  - "traefik.http.middlewares.auth.basicauth.users=admin:$$apr1$$hash..."
  ```
- Enable firewall rules for Docker bridge networks.

---

## 🔊 Troubleshooting

### TLS/ACME Failures
- Check DNS provider credentials (`.env` file)
- Ensure the A-record resolves to your VPS IP
- Confirm `acme.json` permissions: `chmod 600 Traefik/data/acme.json`

### DNS Propagation
```bash
dig +short monitor.anganba.me
```

### Service Health
```bash
sudo ./deploy.sh status
```
or directly:
```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### Debugging ACME
```bash
docker logs traefik | grep acme
```

---

## 🛠️ System Requirements
- Ubuntu Server 24.04 LTS (or equivalent)
- Docker Engine >= 27
- Docker Compose >= 2.23
- Minimum 2GB RAM, 2 vCPU

---

## 🖊️ Repository Structure
```
TraeSentinel/
├── Traefik/
│   ├── docker-compose.yml
│   ├── .env.cloudflare
│   ├── .env.namecheap
│   └── data/
├── Monitoring/
│   ├── prometheus/
│   ├── grafana/
│   ├── cadvisor/
│   └── node-exporter/
├── deploy.sh
├── stack.list
├── README.md
├── docs/
│   ├── DEPLOYMENT_GUIDE.md
│   └── ARCHITECTURE_OVERVIEW.md
└── LICENSE
```

---

## 🗪️ License
**MIT License**  
For educational and demonstration use.

---

## 👨‍💻 Author
**Anganba Singha**  
DevOps | Linux Server Administration | Cybersecurity Enthusiast  
📧 anganba.sananu@gmail.com

