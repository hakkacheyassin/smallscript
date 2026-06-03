#!/bin/bash
# ---------------------------------------------------------
# Script bach t-installer Serveur PXE BACKUP + Keepalived
# ---------------------------------------------------------
set -e

# --- CONFIGURATION ---
VIP_PXE="10.30.30.200"      # VIP dyal TFTP/PXE
MASTER_PXE="10.30.30.104"   # L'IP dyal PXE Master
TFTP_DIR="/srv/tftp"
INTERFACE="ens18"          
# ---------------------

echo "🚀 Bismillah, bdit l'installation dyal PXE Backup (10.30.30.110)..."

apt-get update -y -qq
apt-get install -y dnsmasq keepalived rsync cron

mkdir -p "$TFTP_DIR"

echo "⚙️  Configuration dyal Dnsmasq (TFTP Server)..."
cat <<EOF > /etc/dnsmasq.conf
port=0
enable-tftp
tftp-root=$TFTP_DIR
EOF
systemctl restart dnsmasq
systemctl enable dnsmasq

echo "⚙️  Configuration dyal Keepalived (BACKUP)..."
cat <<EOF > /etc/keepalived/keepalived.conf
vrrp_instance VI_PXE {
    state BACKUP
    interface $INTERFACE
    virtual_router_id 66
    priority 90          
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass PxeHA2026
    }
    virtual_ipaddress {
        $VIP_PXE
    }
}
EOF
systemctl restart keepalived
systemctl enable keepalived

echo "🔄 Configuration dyal Rsync Cron (Synchro kol 5min)..."
CRON_JOB="*/5 * * * * root rsync -avz --delete -e 'ssh -o StrictHostKeyChecking=no' root@$MASTER_PXE:$TFTP_DIR/ $TFTP_DIR/"
if ! grep -q "rsync" /etc/crontab; then
    echo "$CRON_JOB" >> /etc/crontab
fi
systemctl restart cron

echo "=========================================================="
echo "✅ PXE Backup t'installa b naja7 f 10.30.30.110!"
echo "📍 IP VIP PXE hiya: $VIP_PXE"
echo ""
echo "⚠️  DIR HADCHI DABA BACH Y-KHDEM RSYNC:"
echo "   1) ssh-keygen -t rsa -b 4096"
echo "   2) ssh-copy-id root@10.30.30.104"
echo "=========================================================="
