#!/bin/bash
# ============================================================
# EC2 Server Setup Script
# Run this ONCE on your EC2 instance after first launch
# Usage: bash ec2-setup.sh
# ============================================================

set -e

echo "🔧 Updating system packages..."
sudo apt-get update -y && sudo apt-get upgrade -y

# ── Install Node.js 20 ──────────────────────────────────────
echo "📦 Installing Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

echo "Node version: $(node -v)"
echo "NPM version:  $(npm -v)"

# ── Install PM2 (process manager) ───────────────────────────
echo "📦 Installing PM2..."
sudo npm install -g pm2

# Configure PM2 to start on system boot
pm2 startup systemd -u $USER --hp $HOME
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u $USER --hp $HOME

# ── Install rsync (for file transfers) ──────────────────────
sudo apt-get install -y rsync

# ── Create app directory and logs ───────────────────────────
echo "📁 Creating app directories..."
mkdir -p ~/app/logs

# ── Configure firewall (UFW) ─────────────────────────────────
echo "🔒 Configuring firewall..."
sudo ufw allow OpenSSH
sudo ufw allow 3000/tcp     # App port
sudo ufw allow 80/tcp       # HTTP (optional, for nginx later)
sudo ufw allow 443/tcp      # HTTPS (optional, for nginx later)
sudo ufw --force enable

echo ""
echo "✅ EC2 setup complete!"
echo "   Node: $(node -v)"
echo "   NPM:  $(npm -v)"
echo "   PM2:  $(pm2 -v)"
echo ""
echo "👉 Next: Add your GitHub Secrets and push to main branch."
