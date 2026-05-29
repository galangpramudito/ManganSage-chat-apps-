#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────
# Mangansage — Bootstrap script untuk Oracle Cloud VM
# ──────────────────────────────────────────────────────────────────────────
# Jalankan SEKALI saat VM Oracle baru di-provision.
# Image OS yang didukung: Canonical Ubuntu 22.04 / 24.04 (ARM atau AMD).
#
# Cara pakai:
#   1. SSH ke VM:        ssh -i <key> ubuntu@<VM_PUBLIC_IP>
#   2. Upload script:    scp -i <key> oracle-vm-bootstrap.sh ubuntu@<VM_IP>:~
#   3. Run:              chmod +x oracle-vm-bootstrap.sh && ./oracle-vm-bootstrap.sh
#   4. Logout, login ulang (biar group docker aktif)
# ──────────────────────────────────────────────────────────────────────────
set -euo pipefail

echo "▶ Update apt packages..."
sudo apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq

echo "▶ Install dependencies (curl, git, iptables-persistent, ufw)..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    curl \
    git \
    ca-certificates \
    iptables-persistent \
    ufw

# ─── Docker ──────────────────────────────────────────────────────────────
if ! command -v docker >/dev/null 2>&1; then
    echo "▶ Install Docker via get.docker.com..."
    curl -fsSL https://get.docker.com | sudo sh
else
    echo "▶ Docker sudah terinstall: $(docker --version)"
fi

# Tambahkan user ke group docker (perlu logout/login untuk aktif).
if ! groups "$USER" | grep -q docker; then
    sudo usermod -aG docker "$USER"
    echo "  ⚠ Logout & login ulang untuk pakai 'docker' tanpa sudo."
fi

# ─── Firewall (Oracle Ubuntu image punya iptables restriktif by default) ─
echo "▶ Buka port 80, 443 di iptables..."
# Cek apakah rule sudah ada — kalau belum, tambahkan SEBELUM rule REJECT.
if ! sudo iptables -C INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null; then
    sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 80 -j ACCEPT
fi
if ! sudo iptables -C INPUT -p tcp --dport 443 -j ACCEPT 2>/dev/null; then
    sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 443 -j ACCEPT
fi

# Save rules supaya persist saat reboot.
sudo netfilter-persistent save 2>/dev/null || sudo iptables-save | sudo tee /etc/iptables/rules.v4 >/dev/null

# ─── Storage swap (penting buat VM Free Tier 1GB RAM) ─────────────────────
if [ ! -f /swapfile ]; then
    echo "▶ Setup 2GB swap (membantu di VM dengan RAM kecil)..."
    sudo fallocate -l 2G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
fi

# ─── Project directory ───────────────────────────────────────────────────
PROJECT_DIR="$HOME/mangansage"
mkdir -p "$PROJECT_DIR"

# ─── Done ────────────────────────────────────────────────────────────────
cat <<EOF

═══════════════════════════════════════════════════════════════════════
  ✓ Bootstrap selesai!
═══════════════════════════════════════════════════════════════════════

LANGKAH BERIKUTNYA:

  1. Logout & login ulang ke VM (biar group 'docker' aktif):
       exit
       ssh -i <key> $USER@<VM_IP>

  2. Pastikan port 80/443 dibuka juga di OCI Security List:
       https://cloud.oracle.com/networking/vcns
       → VCN Anda → Security Lists → Default → Add Ingress Rules:
         Source: 0.0.0.0/0  | Protocol: TCP | Dest. Ports: 80,443

  3. Dari laptop Windows Anda, jalankan:
       .\\deploy.ps1 -VmIp <VM_PUBLIC_IP>

  4. Setelah deploy pertama, di VM jalankan:
       cd ~/mangansage
       cp .env.production.example .env.production
       nano .env.production         # isi semua placeholder
       docker compose exec app php artisan key:generate --show
       # Paste output ke APP_KEY di .env.production
       docker compose up -d         # restart dengan env baru
       docker compose exec app php artisan migrate --force

  5. Test:
       curl http://<VM_IP>/api/user
       # → 401 Unauthorized = backend hidup ✓

═══════════════════════════════════════════════════════════════════════
EOF
