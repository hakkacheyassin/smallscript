cat << 'EOF' > /tmp/fix-apt.sh
#!/bin/bash

echo "[+] Backing up old sources.list..."
cp /etc/apt/sources.list /etc/apt/sources.list.bak

echo "[+] Writing new sources.list..."

cat > /etc/apt/sources.list << EOL
deb http://deb.debian.org/debian trixie main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
deb http://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware
EOL

echo "[+] Cleaning apt cache..."
apt clean

echo "[+] Updating..."
apt update

echo "[✔] Done!"
EOF

chmod +x /tmp/fix-apt.sh
bash /tmp/fix-apt.sh
