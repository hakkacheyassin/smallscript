#!/bin/bash
# ---------------------------------------------------------
# Automated Setup: NFS BACKUP Server + Keepalived + Rsync
# ---------------------------------------------------------
set -e

# --- CONFIGURATION ---
VIP_NFS="10.30.30.100"      # The Virtual IP (must be available on the network)
MASTER_NFS="10.30.30.104"   # The active Master IP
CLIENT_NETWORK="10.30.30.0/24"
NFS_DIR="/srv/nfs/rootfs"
INTERFACE="ens33"           # ⚠️ Change this to your actual network interface (e.g., eth0)
# ---------------------

echo "🚀 Starting NFS Backup Setup on 10.30.30.109..."

if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run this script as root (sudo)."
  exit 1
fi

echo "📦 [1/4] Installing nfs-kernel-server, keepalived, and rsync..."
apt-get update -y -qq
apt-get install -y nfs-kernel-server keepalived rsync cron nfs-common

echo "📁 [2/4] Creating NFS directory structure..."
mkdir -p "$NFS_DIR"

echo "🔒 [3/4] Configuring NFS Exports (/etc/exports)..."
if ! grep -q "$NFS_DIR" /etc/exports; then
    echo "$NFS_DIR $CLIENT_NETWORK(ro,sync,no_subtree_check,no_root_squash)" >> /etc/exports
fi
exportfs -ra
systemctl enable nfs-kernel-server

echo "⚙️  [4/4] Configuring Keepalived (BACKUP Role)..."
cat <<EOF > /etc/keepalived/keepalived.conf
vrrp_instance VI_NFS {
    state BACKUP
    interface $INTERFACE
    virtual_router_id 55
    priority 90 # ⚠️ Lower priority than the Master
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass NfsHA2026
    }
    virtual_ipaddress {
        $VIP_NFS
    }
}
EOF

systemctl restart keepalived
systemctl enable keepalived

echo "🔄 [5/5] Configuring Rsync Cron Job (Sync every 5 mins)..."
# This pulls the filesystem data from the Master to the Backup
CRON_JOB="*/5 * * * * root rsync -avz --delete -e 'ssh -o StrictHostKeyChecking=no' root@$MASTER_NFS:$NFS_DIR/ $NFS_DIR/"
if ! grep -q "rsync" /etc/crontab; then
    echo "$CRON_JOB" >> /etc/crontab
fi
systemctl restart cron

echo "=========================================================="
echo "✅ NFS Backup successfully installed on 10.30.30.109!"
echo "📍 NFS Virtual IP (VIP) : $VIP_NFS"
echo ""
echo "⚠️  CRUCIAL NEXT STEP: Rsync requires Passwordless SSH!"
echo "   On this Backup machine, run the following commands:"
echo "   1) ssh-keygen -t rsa -b 4096 (Press Enter for all prompts)"
echo "   2) ssh-copy-id root@10.30.30.104"
echo "=========================================================="
