#!/bin/bash
set -e
RESEAU_CLIENTS="10.30.30.0/24"
NFS_DIR="/srv/nfs/rootfs"
UBUNTU_VERSION="noble"
echo "Bismillah bdit l'installation"
apt-get update -y
apt-get install -y nfs-kernel-server debootstrap nfs-common
mkdir -p "$NFS_DIR"
debootstrap --include=openssh-server,sudo,nano,linux-image-generic,initramfs-tools,systemd-sysv "$UBUNTU_VERSION" "$NFS_DIR" http://archive.ubuntu.com/ubuntu
echo -e "proc /proc proc defaults 0 0\nsysfs /sys sysfs defaults 0 0" > "$NFS_DIR/etc/fstab"
echo "pxe-client" > "$NFS_DIR/etc/hostname"
echo "root:changeme" | chroot "$NFS_DIR" chpasswd
echo "$NFS_DIR $RESEAU_CLIENTS(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports
exportfs -ra
systemctl restart nfs-kernel-server
systemctl enable nfs-kernel-server
echo "Nadi ya NFS Nadi l3ez 10.30.30.104"
