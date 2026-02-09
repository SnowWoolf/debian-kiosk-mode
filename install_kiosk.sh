#!/bin/bash
set -e

# === базовый PATH для minimal Debian ===
export PATH=$PATH:/sbin:/usr/sbin:/bin:/usr/bin

USER_NAME=$(logname)
HOME_DIR="/home/$USER_NAME"

echo "== Установка пакетов =="
apt update
apt install -y xorg chromium unclutter x11-xserver-utils

echo "== Отключение sleep/hibernate =="
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

mkdir -p /etc/systemd/logind.conf.d
cat >/etc/systemd/logind.conf.d/nosleep.conf <<EOF
[Login]
HandleLidSwitch=ignore
HandleSuspendKey=ignore
HandleHibernateKey=ignore
HandlePowerKey=ignore
EOF

echo "== Отключение гашения экрана Xorg =="
mkdir -p /etc/X11/xorg.conf.d
cat >/etc/X11/xorg.conf.d/10-monitor.conf <<EOF
Section "ServerFlags"
    Option "BlankTime" "0"
    Option "StandbyTime" "0"
    Option "SuspendTime" "0"
    Option "OffTime" "0"
EndSection
EOF

echo "== kiosk.sh =="

cat >/usr/local/bin/kiosk.sh <<'EOF'
#!/bin/bash

URL_FILE="/etc/kiosk_url"
DEFAULT_URL="http://192.168.202.206:5173/"

if [ -f "$URL_FILE" ]; then
    URL=$(cat $URL_FILE)
else
    URL=$DEFAULT_URL
fi

sleep 3

xset s off
xset -dpms
xset s noblank

xrandr --auto
xrandr --output HDMI-1 --auto 2>/dev/null
xrandr --output HDMI-0 --auto 2>/dev/null
xrandr --output eDP-1 --auto 2>/dev/null

unclutter -idle 0 -root &

while true
do
  chromium \
    --kiosk \
    --start-fullscreen \
    --start-maximized \
    --window-position=0,0 \
    --noerrdialogs \
    --disable-infobars \
    --disable-session-crashed-bubble \
    --disable-translate \
    "$URL"

  sleep 2
done
EOF

chmod +x /usr/local/bin/kiosk.sh

echo "== смена URL =="

cat >/usr/local/bin/kiosk-set-url <<'EOF'
#!/bin/bash
echo "$1" | sudo tee /etc/kiosk_url
echo "URL обновлён. Перезапусти:"
echo "reboot"
EOF

chmod +x /usr/local/bin/kiosk-set-url

echo "== показать IP =="

cat >/usr/local/bin/kiosk-ip <<'EOF'
#!/bin/bash
hostname -I
EOF

chmod +x /usr/local/bin/kiosk-ip

echo "== статический IP =="

cat >/usr/local/bin/kiosk-set-static-ip <<'EOF'
#!/bin/bash

IP=$1
GW=$2
DNS=${3:-8.8.8.8}

IFACE=$(ip route | grep default | awk '{print $5}')

sudo bash -c "cat >/etc/network/interfaces.d/$IFACE <<EOT
auto $IFACE
iface $IFACE inet static
    address $IP
    netmask 255.255.255.0
    gateway $GW
    dns-nameservers $DNS
EOT"

echo "IP задан. reboot"
EOF

chmod +x /usr/local/bin/kiosk-set-static-ip

echo "== .xinitrc =="

cat >"$HOME_DIR/.xinitrc" <<'EOF'
#!/bin/bash
exec /usr/local/bin/kiosk.sh
EOF

chown $USER_NAME:$USER_NAME "$HOME_DIR/.xinitrc"
chmod +x "$HOME_DIR/.xinitrc"

echo "== автозапуск X =="

cat >"$HOME_DIR/.bash_profile" <<'EOF'
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
  startx
fi
EOF

chown $USER_NAME:$USER_NAME "$HOME_DIR/.bash_profile"

echo "== автологин tty1 =="

mkdir -p /etc/systemd/system/getty@tty1.service.d

cat >/etc/systemd/system/getty@tty1.service.d/autologin.conf <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER_NAME --noclear %I \$TERM
EOF

echo
echo "======================================"
echo "ГОТОВО"
echo
echo "Сменить URL:"
echo "sudo kiosk-set-url http://IP:PORT/"
echo
echo "IP терминала:"
echo "kiosk-ip"
echo
echo "Статический IP:"
echo "sudo kiosk-set-static-ip 192.168.1.50 192.168.1.1"
echo
echo "Перезагрузка:"
echo "/sbin/reboot"
echo "======================================"
