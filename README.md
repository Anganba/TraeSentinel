# DNS & Reverse Proxy Infrastructure (Cloudflare + Namecheap)

> A complete self-hosted DNS + reverse proxy stack using **BIND9**, **Traefik**, and **Docker Compose**, supporting both **Cloudflare** *(default)* and **Namecheap** for automated DNS-based SSL certificates via Let’s Encrypt (ACME).  
> Designed as a DevOps lab project for managing custom DNS, HTTPS, and containerized infrastructure.
---

## 🚀 Overview
This project simulates a production-grade DNS and reverse proxy setup:
- **BIND9** acts as an authoritative DNS for your custom domain.
- **Traefik** handles HTTPS termination and automatic certificate generation.
- You can switch between **Cloudflare** or **Namecheap** as the DNS API provider without editing configuration files.
- Managed entirely with a single `deploy.sh` script.

Built and tested on **Ubuntu Server 24.04 LTS** using **Docker Compose**, all services communicate on a shared `frontend` network.

---

## 🧩 Components

| Component | Description |
|------------|-------------|
| **BIND9** | Authoritative DNS server for your internal or public domain (e.g. `anganba.me`) |
| **Traefik v3.5** | Reverse proxy providing HTTPS with automatic certificate renewal |
| **Let's Encrypt (ACME)** | SSL/TLS certificate authority used via DNS challenge |
| **Cloudflare / Namecheap** | Supported DNS APIs for ACME DNS-01 challenge |
| **Nginx** | Example backend web service |
| **Portainer** | Web-based UI for Docker management |

---

## 🧠 Architecture Diagram
```
                ┌─────────────────────┐
                │     Client (Web)    │
                └─────────┬───────────┘
                          │ HTTPS (443)
                          ▼
                ┌──────────────────────┐
                │      Traefik         │
                │  Reverse Proxy + SSL │
                └─────────┬────────────┘
                          │ Internal network (frontend)
          ┌───────────────┴───────────────┐
          │                               │
  ┌──────────────┐              ┌─────────────────┐
  │   Nginx App  │              │   Portainer UI  │
  └──────────────┘              └─────────────────┘
          │                               │
          ▼                               ▼
 nginx.alo.anganba.me        portainer.alo.anganba.me
          │                               │                          
          ▼                               ▼   
┌────────────────────────────────────────────────────┐
│                    BIND9 DNS                       │
│              ns.anganba.me (local)                 │
└────────────────────────────────────────────────────┘
```


---

## ⚙️ Features

- 🔄 Switch between **Cloudflare** and **Namecheap** DNS easily
- 🔐 Automated SSL via Let's Encrypt DNS-01 challenge
- 🧩 Modular services (Traefik, BIND9, Nginx, Portainer)
- 📜 Single deployment script (`deploy.sh`)
- 🧠 Local authoritative DNS management
- 🧱 Real-world DevOps lab setup

---

## 🛠 Setup & Deployment

### 1️⃣ Prerequisites

- A valid domain name (e.g., `anganba.me`)
- API credentials for **Cloudflare** and/or **Namecheap**
- Installed dependencies:
  ```bash
  sudo apt install docker.io docker-compose -y
  ```
- A Linux server or VM (tested on Ubuntu Server 24.04)

---

### 2️⃣ Clone Repository

```bash
git clone https://github.com/Anganba/dns-traefik-lab.git
cd dns-traefik-lab
```

---

### 3️⃣ Configure Provider Environments

You can use either **Cloudflare** *(default)* or **Namecheap**.

#### **For Cloudflare** (`Traefik/.env.cloudflare`)
```env
PROVIDER=cloudflare
ACME_EMAIL=info@yourdomain
CF_DNS_API_TOKEN=your_cloudflare_api_token
```

#### **For Namecheap** (`Traefik/.env.namecheap`)
```env
PROVIDER=namecheap
ACME_EMAIL=info@yourdomain
NAMECHEAP_API_USER=your_username
NAMECHEAP_API_KEY=your_api_key
NAMECHEAP_API_URL=https://api.namecheap.com/xml.response
```

---

### 4️⃣ Adjust DNS Zone File

Update the zone file for your domain in:
```
bind9/config/anganba-me.zone
```

Example:
```dns
ns     IN  A   192.168.68.129
alo    IN  A   192.168.68.129
*.alo  IN  A   192.168.68.129
```

> Replace `192.168.68.129` with your server’s IP address.

---

If you skip this step, DNS queries and SSL validation will fail.

Also Your Namecheap account must have:
API access enabled under “Profile → Tools → Namecheap API Access”.
Your host’s public IP added to the “API Whitelist IPs” section.
If you don't have your local VMs' public IP or VPS IP get whitelisted in the Namecheap API section, TLS Handshake will fail.


### 5️⃣ Deploy the Stack

Create a network called "frontend" since it is hardcoded in the script.
Run:
```bash
sudo docker network create frontend
```

Make the deploy script executable:
```bash
sudo chmod +x deploy.sh
```

Then start the full infrastructure:
```bash
sudo ./deploy.sh up
```

To switch providers:
```bash
sudo ./deploy.sh up namecheap
```


Check running status:
```bash
sudo ./deploy.sh status
```

### The usage of the deploy script:
```
Usage: ./deploy.sh {up|down|restart|status}
  up       Start all services
  down     Stop and remove all services
  restart  Restart all services
  status   Show running containers and health info  
```

## 🌐 Access Services

| Service | URL | Description |
|----------|-----|-------------|
| Traefik Dashboard | https://traefik.alo.anganba.me | Reverse proxy UI (insecure mode ON for lab) |
| Portainer | https://portainer.alo.anganba.me | Docker management UI |
| Nginx Demo | https://nginx.alo.anganba.me | Example app |

---


## 🧪 DNS Testing

Check your DNS server resolution:
```bash
dig @192.168.68.129 portainer.alo.anganba.me
```

Test from client machine:
```bash
nslookup nginx.alo.anganba.me 192.168.68.129
```

---

## 🔒 SSL Certificate Automation

Certificates are automatically generated and renewed using Let’s Encrypt DNS challenge.

Stored in:
```
Traefik/data/certs/cloudflare-acme.json
Traefik/data/certs/namecheap-acme.json
```

Set permissions:
```bash
sudo chmod 600 Traefik/data/certs/*.json
```

---

## 🧱 Troubleshooting

### ⚠️ TLS Handshake Errors
- Check file permissions for ACME files
- Verify DNS A-records resolve correctly
- Wait 5–10 minutes for DNS propagation
- Ensure correct API tokens or keys are in `.env` files

### ⚠️ DNS Not Resolving
- Confirm `named.conf` includes your zone
- Run:  
  ```bash
  docker logs dns-bind9
  ```
  to verify successful zone loading.

### ⚠️ ACME Errors (“NXDOMAIN” or “invalid TLD”)
- Ensure domain/subdomain exists in your DNS zone.
- Let’s Encrypt does **not** issue certificates for internal-only domains (e.g., `.local`).

### ⚠️ Update Your DNS Settings
If you want to access those `https://traefik.yea.zenorahost.com` in your windows or local machine, make sure to point your DNS settings preferred DNS to `VM's IP where DNS server is running` and as alternative DNS use `1.1.1.1` or `8.8.8.8`.



---

## 📂 Project Structure

```text
dns-traefik-lab/
├── bind9/
│   ├── config/
│   │   ├── named.conf
│   │   └── anganba-me.zone
│   ├── cache/
│   ├── records/
│   └── docker-compose.yaml
├── Traefik/
│   ├── config/
│   │   └── traefik.yaml
│   ├── data/certs/
│   │   ├── cloudflare-acme.json
│   │   └── namecheap-acme.json
│   ├── .env.cloudflare
│   ├── .env.namecheap
│   └── docker-compose.yaml
├── nginx/
│   └── docker-compose.yaml
├── Portainer-Server/
│   └── docker-compose.yaml
├── deploy.sh
└── README.md
```


---

## 📸 Demo Screenshots
- `dig` DNS resolution showing correct IP mapping
![DNS Verification](https://github.com/Anganba/ImagesHostedOnGitHub/blob/6f545125cdf5952b9d1d70a1e3bae77f955e3237/dns-traefik-lab-img/DNS_verification.png)
- Traefik dashboard with routers + TLS certs
![Traefik Dashboard](https://github.com/Anganba/ImagesHostedOnGitHub/blob/727c6bbd7b58c6b2a93dafa7e8a694993eb30886/dns-traefik-lab-img/traefik.png)
- NGINX Browser view with HTTPS padlock
![NGINX HTTPS Result](https://github.com/Anganba/ImagesHostedOnGitHub/blob/d8ec622763c0339949da6742d48752bbd697bcc7/dns-traefik-lab-img/nginx.png)
- Portainer dashboard running behind Traefik
![Portainer UI](https://github.com/Anganba/ImagesHostedOnGitHub/blob/584a5bbd3b662971b46e57e0fd224d9fb1c26c54/dns-traefik-lab-img/portainer.png)



---

## 🧩 Future Enhancements

- Add **HAProxy** for load balancing
- Enable **IPv6** for Traefik and BIND9
- Integrate **Grafana + Prometheus** monitoring
- Add **Automatic DNS Sync** with Cloudflare API

---

## 🪪 License
MIT License — Free for educational and demonstration use.

---

## 🌐 Author
**Anganba Singha**
DevOps | Linux Server Administrator | Cybersecurity Enthusiast
