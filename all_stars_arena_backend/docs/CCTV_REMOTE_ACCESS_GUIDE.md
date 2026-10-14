# All Stars Arena — Remote CCTV Access & Deployment Guide

This document provides complete instructions for deploying and configuring the **All Stars Arena Backend** on a court-local computer to enable secure, remote CCTV live streaming over 4G/5G mobile networks and external Wi-Fi.

---

## Architecture Overview

```
[ Mobile App (4G/5G / Remote Wi-Fi) ]
                │
                │ HTTPS (Port 443)
                ▼
  [ DDNS Domain / Public IP ]
                │
                │ Router Port Forwarding (443)
                ▼
  [ Court Reverse Proxy (Nginx / Caddy with SSL) ]
                │
                │ HTTP (Port 5000)
                ▼
  [ All Stars Arena Node.js Backend ]
        │                       │
        │ Socket Probe (554)    │ FFmpeg RTSP (554)
        ▼                       ▼
  [ Dahua DVR / NVR (Local LAN 192.168.1.2) ]
```

---

## 1. Court LAN Setup & Static IP Reservation

1. **Assign Static IP to Backend Machine**:
   - Access the court's Wi-Fi router admin page (e.g., `192.168.1.1`).
   - Navigate to **DHCP / Address Reservation**.
   - Reserve a fixed IP for the court server machine (e.g., `192.168.1.100`).
2. **Dahua DVR IP Assignment**:
   - Ensure the Dahua XVR/DVR is set to a static IP (e.g., `192.168.1.2`) on the same subnet.
   - Default RTSP port: `554`. Default TCP port: `37777`.

---

## 2. Dynamic DNS (DDNS) Configuration

If the court's Internet connection uses a dynamic public IP:

1. **Option A: Router DDNS**:
   - Enable DDNS in router settings using **No-IP**, **DuckDNS**, or **DynDNS**.
   - Example hostname: `cctv-court1.duckdns.org`.
2. **Option B: DuckDNS Script on Court Server**:
   ```bash
   mkdir -p ~/duckdns && cd ~/duckdns
   echo 'echo url="https://www.duckdns.org/update?domains=YOUR_DOMAIN&token=YOUR_TOKEN&ip=" | curl -k -K -' > duck.sh
   chmod 700 duck.sh
   (crontab -l 2>/dev/null; echo "*/5 * * * * ~/duckdns/duck.sh >/dev/null 2>&1") | crontab -
   ```

---

## 3. HTTPS Reverse Proxy Configuration (Nginx / Caddy)

### Nginx Template (`/etc/nginx/sites-available/allstarsarena.conf`)

```nginx
server {
    listen 80;
    server_name cctv-court1.duckdns.org;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name cctv-court1.duckdns.org;

    ssl_certificate /etc/letsencrypt/live/cctv-court1.duckdns.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/cctv-court1.duckdns.org/privkey.pem;

    # HLS Streaming & API Proxy
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;

        # Disable buffering for low-latency HLS
        proxy_buffering off;
    }
}
```

To obtain a free Let's Encrypt SSL certificate:
```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d cctv-court1.duckdns.org
```

---

## 4. Router Firewall & Port Forwarding

1. Log in to the court router configuration.
2. Add Port Forwarding rule:
   - **External Port**: `443` (HTTPS)
   - **Internal IP**: `192.168.1.100` (Court Server Machine)
   - **Internal Port**: `443`
3. ⚠️ **SECURITY CRITICAL**:
   - **DO NOT** forward DVR Port `554` (RTSP) or `37777` to the public internet.
   - All RTSP communication stays strictly internal on the court LAN.

---

## 5. CGNAT / Double-NAT Fallback (Cloudflare Tunnel)

If the court ISP uses Carrier-Grade NAT (CGNAT) where public inbound ports are blocked:

1. Install `cloudflared` on the court server:
   ```bash
   curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
   sudo dpkg -i cloudflared.deb
   ```
2. Authenticate and create a Cloudflare Tunnel:
   ```bash
   cloudflared tunnel login
   cloudflared tunnel create court-cctv
   ```
3. Configure `~/.cloudflared/config.yml`:
   ```yaml
   tunnel: <TUNNEL_ID>
   credentials-file: /root/.cloudflared/<TUNNEL_ID>.json

   ingress:
     - hostname: cctv-court1.yourdomain.com
       service: http://localhost:5000
     - service: http_status:404
   ```
4. Run as system service:
   ```bash
   sudo cloudflared service install
   sudo systemctl start cloudflared
   ```

---

## 6. Environment Configuration (`all_stars_arena_backend/.env`)

```ini
PORT=5000
NODE_ENV=production
BACKEND_URL=https://cctv-court1.duckdns.org

# CCTV Settings
CAMERA_HOST=192.168.1.2
CAMERA_RTSP_PORT=554
CAMERA_USERNAME=admin
CAMERA_PASSWORD=admin@123
FFMPEG_PATH=ffmpeg
```

---

## 7. OS Firewall & Systemd Auto-Restart Service

### Ubuntu UFW Firewall:
```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

### Systemd Auto-Restart Service (`/etc/systemd/system/allstars-backend.service`):
```ini
[Unit]
Description=All Stars Arena Backend API
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/all_stars_arena_backend
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable allstars-backend
sudo systemctl start allstars-backend
```

---

## 8. Mobile 4G/5G Verification Checklist

- [ ] Turn off Wi-Fi on test mobile device (use 4G/5G cellular data).
- [ ] Open All Stars Arena app logged in as Manager or Admin.
- [ ] Navigate to **Live CCTV Network**.
- [ ] Verify that camera channels are discovered and status shows **ONLINE**.
- [ ] Tap on a camera tile to view live HLS footage.
- [ ] Verify HD/SD stream toggle works smoothly.
