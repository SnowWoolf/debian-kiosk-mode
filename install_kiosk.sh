#!/bin/bash
set -e
export PATH=$PATH:/sbin:/usr/sbin:/bin:/usr/bin

USER_NAME=$(logname)
HOME_DIR="/home/$USER_NAME"

echo "== install packages =="
apt update
apt install -y xorg chromium unclutter x11-xserver-utils

echo "== allow X for systemd =="
cat >/etc/X11/Xwrapper.config <<EOF
allowed_users=anybody
needs_root_rights=yes
EOF

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

sleep 3

OUTPUT=$(xrandr | grep " connected" | head -n1 | cut -d" " -f1)
xrandr --output "$OUTPUT" --auto

xset -dpms
xset s off
xset s noblank

unclutter -idle 0 -root &

while true
do
  chromium --kiosk --start-maximized "$URL"
  sleep 2
done
EOF

chmod +x /usr/local/bin/kiosk.sh

echo "== systemd kiosk service =="
cat >/etc/systemd/system/kiosk.service <<EOF
[Unit]
Description=Kiosk
After=systemd-user-sessions.service network.target

[Service]
User=$USER_NAME
Environment=DISPLAY=:0
Environment=XAUTHORITY=$HOME_DIR/.Xauthority
ExecStart=/usr/bin/startx /usr/local/bin/kiosk.sh -- :0
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

echo "== URL command =="
cat >/usr/local/bin/kiosk-set-url <<'EOF'
#!/bin/bash
echo "$1" | sudo tee /etc/kiosk_url
echo "reboot"
EOF
chmod +x /usr/local/bin/kiosk-set-url

echo "== show IP command =="
cat >/usr/local/bin/kiosk-ip <<'EOF'
#!/bin/bash
hostname -I
EOF
chmod +x /usr/local/bin/kiosk-ip

echo "== static IP command =="
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

echo "== enable service =="
systemctl daemon-reload
systemctl enable kiosk.service

echo
echo "INSTALL COMPLETE"
echo "Reboot required:"
echo "/sbin/reboot"
