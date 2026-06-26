#!/usr/bin/env bash
set -e

PRINTER_NAME="Blueprint_BP-LITE80D1"
PRINTER_DESCRIPTION="Blueprint_BP-LITE80D1"
PRINTER_LOCATION="Anjungan KirimObat"
PRINTER_DRIVER="zjiang/zj80.ppd"

echo "========================================"
echo "Update Package"
echo "========================================"

sudo apt update
sudo apt install -y git curl wget python3 ca-certificates gnupg apt-transport-https

echo "========================================"
echo "Clone Project"
echo "========================================"

if [ ! -d billacceptorprint ]; then
    git clone https://github.com/lmugmxpolinema/billacceptorprint.git
fi

cd billacceptorprint

echo "========================================"
echo "Install Brave Browser"
echo "========================================"

curl -fsS https://dl.brave.com/install.sh | sh

echo "========================================"
echo "Install AnyDesk"
echo "========================================"

sudo install -m 0755 -d /etc/apt/keyrings

sudo curl -fsSL https://keys.anydesk.com/repos/DEB-GPG-KEY \
-o /etc/apt/keyrings/keys.anydesk.com.asc

sudo chmod a+r /etc/apt/keyrings/keys.anydesk.com.asc

echo "deb [signed-by=/etc/apt/keyrings/keys.anydesk.com.asc] https://deb.anydesk.com all main" | \
sudo tee /etc/apt/sources.list.d/anydesk-stable.list >/dev/null

sudo apt update
sudo apt install -y anydesk

echo "========================================"
echo "Run Printer Setup"
echo "========================================"

python3 setupprint.py

echo "========================================"
echo "Configure Blueprint Printer"
echo "========================================"

sudo systemctl enable cups
sudo systemctl restart cups

DEVICE=$(lpinfo -v | awk '/BP-LITE80D1/ {print $2; exit}')

if [ -z "$DEVICE" ]; then
    echo "Printer BP-LITE80D1 tidak ditemukan."
    exit 1
fi

if lpstat -p "$PRINTER_NAME" >/dev/null 2>&1; then
    sudo lpadmin -x "$PRINTER_NAME"
fi

sudo lpadmin \
    -p "$PRINTER_NAME" \
    -D "$PRINTER_DESCRIPTION" \
    -L "$PRINTER_LOCATION" \
    -E \
    -v "$DEVICE" \
    -m "$PRINTER_DRIVER"

sudo lpadmin \
    -p "$PRINTER_NAME" \
    -o OptionCutter=True \
    -o PageSize=X70MMY105MM \
    -o CutMedia=EndOfPage

sudo lpoptions -d "$PRINTER_NAME"

sudo systemctl restart cups

echo "========================================"
echo "Setup Brave Kiosk"
echo "========================================"

mkdir -p ~/.config/autostart

cat > ~/.config/autostart/kiosk.desktop <<EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=Kiosk
Comment=Brave Kiosk Mode
Exec=brave-browser --kiosk --incognito --password-store=basic --no-first-run --disable-session-crashed-bubble https://app.xpdisi.id https://dash.kirimobat.com
Terminal=false
X-GNOME-Autostart-enabled=true
EOF

chmod +x ~/.config/autostart/kiosk.desktop

echo "========================================"
echo "Verifikasi"
echo "========================================"

echo "Brave Version:"
brave-browser --version || true

echo
echo "AnyDesk Version:"
anydesk --version || true

echo
echo "Printer:"
lpstat -p

echo
echo "Default Printer:"
lpstat -d

echo
echo "========================================"
echo "INSTALLATION COMPLETED"
echo "========================================"

