#!/bin/bash
# ---------------------------------------------------------
# Simple Script to Install PXE (TFTP) Server
# ---------------------------------------------------------
set -e

# IP of the NFS Server (where the OS and kernel were installed)
NFS_SERVER_IP="10.30.30.104"
NFS_ROOT_DIR="/srv/nfs/rootfs"

# Path where PXE and TFTP files will be stored
TFTP_DIR="/srv/tftp"
PXELINUX_CFG="$TFTP_DIR/pxelinux.cfg"

echo "🚀 Starting PXE Server installation..."

if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run this script as root (e.g., sudo ./pxe.sh)"
  exit 1
fi

echo "📦 [1/4] Installing tftpd-hpa, syslinux, and pxelinux packages..."
apt-get update -y -qq
apt-get install -y tftpd-hpa syslinux pxelinux nfs-common

echo "📁 [2/4] Creating TFTP directory and copying bootloaders..."
mkdir -p "$TFTP_DIR"
mkdir -p "$PXELINUX_CFG"

# Copy files needed to boot the system
cp /usr/lib/PXELINUX/pxelinux.0 "$TFTP_DIR/" 2>/dev/null || cp /usr/lib/syslinux/pxelinux.0 "$TFTP_DIR/"
cp /usr/lib/syslinux/modules/bios/ldlinux.c32 "$TFTP_DIR/" 2>/dev/null

echo "⏳ [3/4] Fetching vmlinuz (Kernel) and initrd from NFS Server..."
# Temporarily mount the NFS share to copy the kernel and initrd
TEMPMOUNT="/mnt/nfstemp"
mkdir -p $TEMPMOUNT
mount -t nfs "$NFS_SERVER_IP:$NFS_ROOT_DIR" "$TEMPMOUNT"

# Find the latest kernel and initrd versions
KERNEL_FILE=$(find "$TEMPMOUNT/boot" -name 'vmlinuz-*' -type f | sort -V | tail -1)
INITRD_FILE=$(find "$TEMPMOUNT/boot" -name 'initrd.img-*' -type f | sort -V | tail -1)

if [ -n "$KERNEL_FILE" ] && [ -n "$INITRD_FILE" ]; then
    cp "$KERNEL_FILE" "$TFTP_DIR/vmlinuz"
    cp "$INITRD_FILE" "$TFTP_DIR/initrd.img"
    echo "✔️  Kernel and Initrd copied successfully!"
else
    echo "❌ Error: Could not find vmlinuz or initrd on the NFS server in $NFS_ROOT_DIR/boot"
    umount "$TEMPMOUNT"
    exit 1
fi

umount "$TEMPMOUNT"
rm -rf "$TEMPMOUNT"

echo "⚙️  [4/4] Configuring the default PXE boot menu..."
cat <<EOF > "$PXELINUX_CFG/default"
DEFAULT linux
PROMPT 1
TIMEOUT 50

LABEL linux
  MENU LABEL Boot Linux (Ubuntu 24.04 Diskless via NFS)
  KERNEL vmlinuz
  APPEND initrd=initrd.img root=/dev/nfs nfsroot=$NFS_SERVER_IP:$NFS_ROOT_DIR ip=dhcp rw
EOF

# Ensure TFTP directory is correctly set in configuration
sed -i 's|TFTP_DIRECTORY=.*|TFTP_DIRECTORY="/srv/tftp"|' /etc/default/tftpd-hpa
systemctl restart tftpd-hpa
systemctl enable tftpd-hpa

echo "=========================================================="
echo "✅ PXE setup completed successfully!"
echo "📍 TFTP/PXE Directory : $TFTP_DIR"
echo "🌐 Connected to NFS   : $NFS_SERVER_IP:$NFS_ROOT_DIR"
echo ""
echo "⚠️  Next Step: Go to PFSense -> DHCP Server for VLAN 10.30.30.0/24"
echo "   - Check 'Enables network booting'"
echo "   - Next-server or TFTP Server : Enter the IP of THIS machine (PXE Server)"
echo "   - Default BIOS file name : pxelinux.0"
echo "=========================================================="
