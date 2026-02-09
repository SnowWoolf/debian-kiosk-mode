#!/bin/bash
set -e
export PATH=$PATH:/sbin:/usr/sbin:/bin:/usr/bin

USER_NAME=$(logname)
HOME_DIR="/home/$USER_NAME"

echo "== install packages =="
apt update
apt install -y xorg openbox chromium unclutter x11-xserver-utils

echo "== disable sleep =="
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

mkdir -p /etc/systemd/logind.conf.d
cat >/etc/systemd/logind.conf.d/nosleep.conf <<EOF
[Login]
HandleLidSwitch=ignore
HandleSuspendKey=ignore
HandleHibernateKey=ignore
HandlePowerKey=ignore
EOF

echo "== disable screen blank =="
mkdir -p /etc/X11/xorg.conf.d
cat >/etc/X11/xorg.conf.d/10-monitor.conf <<EOF
Section "ServerFlags"
    Option "BlankTime" "0"
    Option "StandbyTime" "0"
    Option "SuspendTime" "0"
    Option "OffTime" "0"
EndSection
EOF

echo "== kiosk script =="

cat >/usr/local/bin/kiosk.sh <<'EOF'
#!/bin/bash

URL_FILE="/etc/kiosk_url"
DEFAULT_URL="http://192.168.202.206:5173/"

[ -f "$URL_FILE" ] && URL=$(cat $URL_FILE) || URL=$DEFAULT_URL

# ждём X
sleep 4

# отключаем энергосбережение
xset s off
xset -dpms
xset s noblank

# фиксируем разрешение
OUTPUT=$(xrandr | grep " connected" | head -n1 | cut -d" " -f1)
xrandr --output "$OUTPUT" --auto

sleep 2

unclutter -idle 0.01 -root -grab -visible false &

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

echo "== URL command =="

cat >/usr/local/bin/kiosk-set-url <<'EOF'
#!/bin/bash
echo "$1" | sudo tee /etc/kiosk_url
echo "reboot"
EOF
chmod +x /usr/local/bin/kiosk-set-url

echo "== IP command =="

cat >/usr/local/bin/kiosk-ip <<'EOF'
#!/bin/bash
hostname -I
EOF
chmod +x /usr/local/bin/kiosk-ip

echo "== static ip =="

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

echo reboot
EOF
chmod +x /usr/local/bin/kiosk-set-static-ip

echo "== openbox autostart =="

mkdir -p $HOME_DIR/.config/openbox

cat >$HOME_DIR/.config/openbox/autostart <<'EOF'
#!/bin/bash
/usr/local/bin/kiosk.sh
EOF

chown -R $USER_NAME:$USER_NAME $HOME_DIR/.config

echo "== startx =="

cat >$HOME_DIR/.xinitrc <<'EOF'
#!/bin/bash
exec openbox-session
EOF

chown $USER_NAME:$USER_NAME $HOME_DIR/.xinitrc

echo "== autostart X =="

cat >$HOME_DIR/.bash_profile <<'EOF'
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
  startx
fi
EOF

chown $USER_NAME:$USER_NAME $HOME_DIR/.bash_profile

echo "== autologin =="

mkdir -p /etc/systemd/system/getty@tty1.service.d
cat >/etc/systemd/system/getty@tty1.service.d/autologin.conf <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER_NAME --noclear %I \$TERM
EOF

echo
echo "READY"
echo "Выполни /sbin/reboot"
