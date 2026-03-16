# 🚀 Deploy Node.js App on EC2 with GitHub Actions
## Complete Step-by-Step Guide

---

## 📁 Project Structure

```
sample-app/
├── .github/
│   └── workflows/
│       └── deploy.yml        ← GitHub Actions pipeline
├── src/
│   └── app.js                ← Express server
├── public/
│   └── index.html            ← Frontend page
├── app.test.js               ← Jest tests
├── ec2-setup.sh              ← One-time EC2 setup script
├── package.json
└── .gitignore
```

---

## STEP 1 — Create a GitHub Repository

1. Go to https://github.com/new
2. Name it: `ec2-deployed-app`
3. Set visibility to **Public** (or Private)
4. Click **Create repository**
5. On your local machine, run:

```bash
# Clone or init
git clone https://github.com/YOUR_USERNAME/ec2-deployed-app.git
cd ec2-deployed-app

# Copy all the project files into this folder
# Then commit and push
git add .
git commit -m "Initial commit"
git push origin main
```

---

## STEP 2 — Launch an EC2 Instance on AWS

### 2.1 — Go to AWS Console
- Sign in at https://console.aws.amazon.com
- Navigate to **EC2 → Instances → Launch Instance**

### 2.2 — Configure the Instance

| Setting            | Value                          |
|--------------------|--------------------------------|
| Name               | `my-node-app-server`           |
| AMI                | Ubuntu Server 24.04 LTS (Free Tier) |
| Instance Type      | `t2.micro` (Free Tier eligible)|
| Key Pair           | Create new → Name: `my-ec2-key` → Download `.pem` file |
| Network            | Default VPC                    |
| Auto-assign IP     | **Enable**                     |

### 2.3 — Configure Security Group

Click **"Create security group"** and add these **Inbound Rules**:

| Type        | Protocol | Port | Source    | Purpose             |
|-------------|----------|------|-----------|---------------------|
| SSH         | TCP      | 22   | My IP     | Terminal access     |
| Custom TCP  | TCP      | 3000 | 0.0.0.0/0 | Node.js App        |
| HTTP        | TCP      | 80   | 0.0.0.0/0 | (Optional) Nginx   |

### 2.4 — Launch & Note the Public IP

After launching, go to **Instances** and copy your instance's:
- **Public IPv4 address** (e.g., `54.123.45.67`)

---

## STEP 3 — Setup the EC2 Server

### 3.1 — SSH into your EC2 Instance

```bash
# Replace with your actual key path and EC2 IP
chmod 400 ~/Downloads/my-ec2-key.pem

ssh -i ~/Downloads/my-ec2-key.pem ubuntu@54.123.45.67
```

### 3.2 — Run the Setup Script

Once inside EC2, copy and run the `ec2-setup.sh` contents:

```bash
# On EC2 — paste and run:
curl -sO https://raw.githubusercontent.com/YOUR_USERNAME/ec2-deployed-app/main/ec2-setup.sh
bash ec2-setup.sh
```

OR copy-paste the script contents manually. This installs:
- ✅ Node.js 20
- ✅ PM2 (process manager with auto-restart)
- ✅ rsync
- ✅ UFW firewall rules

### 3.3 — Verify Setup

```bash
node -v    # Should show v20.x.x
pm2 -v     # Should show version number
```

---

## STEP 4 — Add GitHub Secrets

GitHub Actions needs 3 secrets to connect to your EC2 instance.

### 4.1 — Open GitHub Secrets
Go to your repo:
**Settings → Secrets and variables → Actions → New repository secret**

### 4.2 — Add These 3 Secrets

#### Secret 1: `EC2_SSH_KEY`
This is the **entire content** of your `.pem` file.

```bash
# On your local machine, run:
cat ~/Downloads/my-ec2-key.pem
```

Copy the entire output including `-----BEGIN RSA PRIVATE KEY-----`
and `-----END RSA PRIVATE KEY-----` lines.

Paste it as the value of `EC2_SSH_KEY`.

#### Secret 2: `EC2_HOST`
Your EC2's **Public IPv4 address**.

```
Value: 54.123.45.67
```

#### Secret 3: `EC2_USER`
The default SSH username for Ubuntu AMI.

```
Value: ubuntu
```

> ⚠️ For Amazon Linux AMIs, the user is `ec2-user` instead.

---

## STEP 5 — Understand the GitHub Actions Pipeline

The file `.github/workflows/deploy.yml` does this on every push to `main`:

```
Push to main
    │
    ▼
┌─────────────────────┐
│   JOB 1: test       │  ← Runs npm test (Jest)
│   ubuntu-latest     │
└──────────┬──────────┘
           │ (only if tests PASS)
           ▼
┌─────────────────────┐
│   JOB 2: deploy     │
│   ubuntu-latest     │
│                     │
│  1. Write .pem key  │
│  2. rsync files     │  ← Copies code to EC2
│     to EC2          │
│  3. SSH → npm ci    │  ← Installs prod deps
│  4. SSH → pm2       │  ← Restarts app
│     reload          │
│  5. Health check    │  ← curl /health → 200?
│  6. Cleanup .pem    │
└─────────────────────┘
```

---

## STEP 6 — Deploy! Push Code to main

```bash
# Make a small change to trigger the pipeline
echo "# Deployed!" >> README.md

git add .
git commit -m "Trigger deployment"
git push origin main
```

### Watch it run:
Go to your GitHub repo → **Actions** tab

You'll see the workflow running with live logs:
```
✅ Run Tests        — 15s
✅ Setup SSH Key    — 1s
✅ Copy files to EC2 — 5s
✅ Deploy on EC2    — 10s
✅ Health Check     — 5s
✅ Cleanup SSH Key  — 1s
```

---

## STEP 7 — Verify the Deployment

### Check the app in browser:
```
http://54.123.45.67:3000
```

### Check health endpoint:
```
http://54.123.45.67:3000/health
```

Expected response:
```json
{
  "status": "OK",
  "message": "App is running",
  "timestamp": "2026-03-14T12:00:00.000Z",
  "version": "abc1234..."
}
```

### Check on EC2:
```bash
ssh -i my-ec2-key.pem ubuntu@54.123.45.67

pm2 list        # Should show my-app as "online"
pm2 logs my-app # Live logs
pm2 monit       # CPU/Memory dashboard
```

---

## STEP 8 — (Optional) Add Nginx + Custom Domain

### 8.1 — Install Nginx on EC2
```bash
sudo apt install nginx -y
```

### 8.2 — Create Nginx Config
```bash
sudo nano /etc/nginx/sites-available/myapp
```

Paste this:
```nginx
server {
    listen 80;
    server_name your-domain.com;   # or your EC2 public IP

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### 8.3 — Enable and Restart
```bash
sudo ln -s /etc/nginx/sites-available/myapp /etc/nginx/sites-enabled/
sudo nginx -t                    # Test config
sudo systemctl restart nginx
```

Now the app is accessible at:
```
http://54.123.45.67        ← Port 80 (no port number needed)
http://your-domain.com     ← If you added DNS A record
```

---

## 🔒 Security Best Practices

| Practice | How |
|----------|-----|
| Never commit `.pem` files | `.gitignore` already excludes `*.pem` |
| Rotate secrets regularly | GitHub → Settings → Secrets |
| Restrict SSH to your IP | Security Group: SSH source = My IP |
| Use Elastic IP | Prevents IP change on EC2 restart |
| Enable SSL/HTTPS | Use Let's Encrypt with Certbot |

---

## 🐛 Troubleshooting

### Pipeline fails at "Copy files to EC2"
- Check `EC2_HOST`, `EC2_USER`, `EC2_SSH_KEY` secrets are correct
- Ensure port 22 is open in EC2 Security Group

### App not accessible at port 3000
- Confirm Security Group has inbound TCP 3000 rule
- Check PM2 is running: `pm2 list`

### Health check fails
- Check `pm2 logs my-app` for errors
- Verify app listens on `0.0.0.0` (not `localhost`)

### PM2 not found on EC2
- Run `ec2-setup.sh` again
- Or manually: `sudo npm install -g pm2`

---

## 📋 Summary: What You Built

```
Developer → git push → GitHub
                           │
                    GitHub Actions
                           │
                 ┌─────────┴──────────┐
                 │   Test → Deploy    │
                 └─────────┬──────────┘
                           │ rsync + SSH
                           ▼
                    AWS EC2 (Ubuntu)
                      PM2 + Node.js
                           │
                    http://your-ip:3000
```

Every time you push to `main`:
1. Tests run automatically
2. If tests pass, code deploys to EC2
3. App restarts with zero-downtime via PM2
4. Health check confirms it's live

**Total time to set up: ~30 minutes** ⏱️
