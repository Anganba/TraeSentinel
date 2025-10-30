# TraeSentinel: Automated Reverse Proxy & Monitoring Stack

A complete **production-ready reverse proxy and observability stack** built using **Traefik v3**, **Docker Compose**, and **Grafana’s monitoring ecosystem** — seamlessly integrating **Cloudflare (default)** or **Namecheap** DNS APIs for automated DNS-based SSL certificates via **Let’s Encrypt (ACME)**.  
Designed as a **DevOps-grade system** for managing secure HTTPS routing, metrics, logs, and visualization — all automated, modular, and easy to scale.

---

## 🚀 Overview

This project provides a **secure and observable infrastructure platform** for your containerized applications:

- **Traefik v3** acts as a reverse proxy with automatic SSL, HTTPS redirection, and middleware-based hardening.  
- **Cloudflare / Namecheap** integration enables zero-downtime SSL management via DNS-01 challenges.  
- **Grafana + Prometheus + Loki** provide full observability — metrics, logs, and visualization.  
- **Node Exporter**, **Promtail**, and **cAdvisor** collect and expose system and container metrics.  
- **Grafana Alloy** extends observability to **remote servers** for distributed environments.  
- Fully managed with a single, intelligent automation system using `deploy.sh` and `stack.list`.  

> 🧠 Built and tested on **Ubuntu Server 24.04 LTS** using **Docker Compose**, with all services isolated into `frontend` and `monitoring` networks.

---

## 🧩 Intelligent Stack Management with `deploy.sh` + `stack.list`

One of the most powerful features of TraeSentinel is its **modular scaling capability**.  
The `deploy.sh` script automatically reads from a **stack.list** file, which defines all the Docker Compose stacks to be launched.

Each line in `stack.list` represents a path to a compose file — allowing you to add or remove entire stacks with ease.  

Example:
```
Traefik/docker-compose.yaml
Portainer-Server/docker-compose.yaml
Prometheus/docker-compose.yaml
Grafana/docker-compose.yaml
Loki/docker-compose.yaml
Promtail/docker-compose.yaml
```
To include a new service (e.g., n8n), simply add:
```
n8n/docker-compose.yaml
```
and redeploy with:
```bash
sudo ./deploy.sh up
```
The script will automatically integrate the new service, attach it to the appropriate network, and provision SSL via Traefik — no manual edits required.

> 🧩 The combination of `deploy.sh` and `stack.list` makes TraeSentinel **infinitely extensible**, suitable for production or personal DevOps labs.

---

## 🖼️ Demo Screenshots

Below are some example views from the live stack (replace with your hosted image links when publishing):

### 🔹 Traefik Dashboard  
![Traefik Dashboard](https://github.com/yourusername/TraeSentinel/assets/demo-traefik-dashboard)

### 🔹 Middleware & Security Headers View  
![Traefik Middleware](https://github.com/yourusername/TraeSentinel/assets/demo-middleware)

### 🔹 Grafana Custom Dashboard  
![Grafana Dashboard](https://github.com/yourusername/TraeSentinel/assets/demo-grafana-dashboard)

### 🔹 Loki Dashboard (Logs Aggregation)  
![Loki Dashboard](https://github.com/yourusername/TraeSentinel/assets/demo-loki-dashboard)

### 🔹 Prometheus Metrics View  
![Prometheus Metrics](https://github.com/yourusername/TraeSentinel/assets/demo-prometheus-dashboard)

### 🔹 Basic Auth Login Screen (Example for Secured Routes)  
![Basic Auth UI](https://github.com/yourusername/TraeSentinel/assets/demo-basic-auth)

---



## 🚀 Quick Start

```bash
# Clone and enter the repository
git clone https://github.com/Anganba/TraeSentinel.git
cd TraeSentinel

# Create required Docker networks
sudo docker network create frontend
sudo docker network create monitoring

# Copy the example environment file for your DNS provider

# 👉 For Cloudflare:
cp Traefik/.env.cloudflare.example Traefik/.env.cloudflare
# Edit it to include your domain, email, and Cloudflare API token

# 👉 For Namecheap:
cp Traefik/.env.namecheap.example Traefik/.env.namecheap
# Edit it to include your Namecheap API credentials

# Make the deploy script executable
sudo chmod +x deploy.sh

# Deploy using your selected provider
sudo ./deploy.sh up cloudflare
# or
sudo ./deploy.sh up namecheap
```

> TraeSentinel automatically provisions HTTPS, secure headers, and DNS-based SSL certificates.  
> HTTP is globally redirected to HTTPS using Traefik’s native redirection and middleware.

---

### 🌍 Domain & DNS Setup (Required for Cloudflare)

Before starting the stack, make sure your domain DNS records are correctly configured on **Cloudflare**.

You’ll need to create the following **A records** under your root domain, all pointing to your server’s public IP:

| Type | Name | Value | Proxy Status |
|------|------|--------|---------------|
| A | traefik | your_server_ip | DNS only |
| A | mon | your_server_ip | DNS only |
| A | portainer | your_server_ip | DNS only |
| A | prometheus | your_server_ip | DNS only |
| A | loki | your_server_ip | DNS only |

> ⚠️ Make sure **Proxy Status** is set to **“DNS only”**, not proxied (the gray cloud icon).  
> This allows Let’s Encrypt (ACME) to validate your DNS records via the DNS-01 challenge.

---

## 🧱 Stack Overview

| Component | Role | Access URL |
|------------|------|------------|
| **Traefik Dashboard** | Reverse proxy, SSL & routing control | `https://traefik.anganba.me` |
| **Grafana** | Visualization and alerting hub | `https://mon.anganba.me` |
| **Prometheus** | Metrics collector backend | Internal only |
| **Loki** | Centralized logs from all containers | Internal only |
| **Portainer** | Docker management UI | `https://portainer.anganba.me` |
| **Node Exporter** | Host-level metrics exporter | Internal only |
| **cAdvisor** | Container metrics exporter | Internal only |
| **Promtail** | Log shipper to Loki | Internal only |
| **Grafana Alloy** | Remote monitoring agent for external targets | Deployed separately |

---

## 🔐 Security by Default

TraeSentinel ships with secure, hardened defaults:
- Automatic HTTP → HTTPS redirection
- `secure-headers` middleware applied globally (HSTS, XSS filter, content-type nosniff)
- TLS certificates auto-issued via DNS-01 challenge (Cloudflare or Namecheap)
- Optional Basic Auth middleware for dashboards

Example Traefik security labels:

```yaml
- "traefik.http.middlewares.secure-headers.headers.STSSeconds=31536000"
- "traefik.http.middlewares.secure-headers.headers.STSIncludeSubdomains=true"
- "traefik.http.middlewares.secure-headers.headers.STSPreload=true"
```

---

## 🧠 Monitoring Architecture

### **Grafana + Prometheus + Loki**

Together they form the backbone of TraeSentinel’s observability layer:
- Prometheus scrapes metrics from Traefik, Node Exporter, cAdvisor, and Alloy.
- Loki aggregates logs collected by Promtail.
- Grafana visualizes metrics and logs through unified dashboards.

### **Grafana Dashboards**

Your custom dashboards are located in:
```
Grafana_Dashboards/
```

You can import them into Grafana manually:
1. Go to **Grafana → Dashboards → Import**.
2. Upload the JSON file from `Grafana_Dashboards/`.
3. Set the data source to **Prometheus**.
4. Save — your tailored monitoring views are ready.

---

## 🧩 Node & Container Metrics

| Exporter | Purpose | Data Source |
|-----------|----------|--------------|
| **Node Exporter** | CPU, RAM, Disk, IO, Network metrics | Host system |
| **cAdvisor** | Container-level stats | Docker runtime |
| **Promtail** | Log collection | Local Docker & system logs |

These are automatically discovered by Prometheus in the internal `monitoring` network.

---

## 🌐 Grafana Alloy: External Target Monitoring

TraeSentinel supports **Grafana Alloy**, the new unified agent for collecting metrics, logs, and traces from remote servers.

### 📘 Official Documentation  
Follow Grafana’s setup guide:  
👉 [Grafana Alloy Installation Guide](https://grafana.com/docs/alloy/latest/set-up/install/)

### 🧭 Integration Steps (for external targets)
1. **Install Grafana Alloy** on your remote host using the link above.
2. Configure Alloy to scrape local system metrics and send them to your main TraeSentinel server:
   - Point its Prometheus remote_write URL to your Prometheus endpoint (internal or via VPN/tunnel).
   - Configure Loki logs endpoint (optional).
3. Restart Alloy and confirm that metrics appear in Grafana under your configured dashboard.

> ⚡ Tip: You can reuse `Grafana_Alloy/config.alloy` as a reference configuration for your targets.

---

## 🧰 Management Commands

```bash
sudo ./deploy.sh up          # Start the full stack
sudo ./deploy.sh down        # Stop all containers
sudo ./deploy.sh restart     # Restart everything
sudo ./deploy.sh status      # Show container health summary
```

`deploy.sh` automatically:
- Detects Docker / Podman Compose
- Loads provider-specific environment files
- Dynamically composes all services listed in `stack.list`
- Prints colored logs with timestamps

---

## 🛠️ System Requirements

| Resource | Minimum |
|-----------|----------|
| OS | Ubuntu Server 24.04 LTS |
| RAM | 2 GB |
| vCPUs | 2 |
| Disk | 10 GB+ (SSD recommended) |
| Docker | ≥ 27 |
| Docker Compose | ≥ 2.23 |

---

## 🗂️ Project Structure

```
TraeSentinel/
├── Traefik/
│   ├── docker-compose.yml
│   ├── .env.cloudflare.example
│   ├── .env.namecheap.example
│   ├── data/
│   └── logs/
│
├── Grafana/
│   ├── docker-compose.yml
│   └── Grafana_Dashboards/
│
├── Grafana_Alloy/
│   └── config.alloy
│
├── Prometheus/
│   ├── docker-compose.yml
│   └── config/
│
├── Loki/
│   └── config/
│
├── node-exporter/
├── cadvisor/
├── Portainer-Server/
├── Promtail/
├── Tempo/
├── deploy.sh
├── stack.list
├── LICENSE
└── README.md
```

---

## 🔎 Troubleshooting

### SSL or DNS Issues
```bash
docker logs traefik | grep acme
```
Ensure your `.env` file credentials and domain names are correct.

### DNS Check
```bash
dig +short mon.anganba.me
```

### Check Service Health
```bash
sudo ./deploy.sh status
```

### Permission Fix (ACME)
```bash
chmod 600 Traefik/data/*.json
```

---

## 🧤 Security Recommendations

- Change default credentials in Grafana (`admin / changeme`).
- Protect Traefik and Portainer dashboards using BasicAuth.
- Enable UFW or firewalld rules for `80` and `443` only.
- Use Cloudflare Access or reverse VPN for production-grade isolation.

---

## 🪄 Credits & License

**License:** MIT  
Developed by **Anganba Singha**  
DevOps | Linux | Cloud Infrastructure | Security  

📧 anganba.sananu@gmail.com  
🌐 [Grafana Alloy Docs](https://grafana.com/docs/alloy/latest/set-up/install/)

---

⭐ *If you find TraeSentinel helpful, star the repo and share your dashboards!*
