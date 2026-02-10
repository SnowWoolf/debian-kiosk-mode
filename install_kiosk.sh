#!/bin/bash
set -e

### ===== НАСТРОЙКИ =====
USER_NAME="user"
SERVER_IP="192.168.203.86"
URL="http://192.168.203.86:8080"

echo "=== INSTALL KIOSK ==="

apt update
apt install -y \
    xorg \
    openbox \
    chromium \
    unclutter \
    xdotool \
    wmctrl \
    curl

### ===== АВТОЛОГИН В TTY1 =====
mkdir -p /etc/systemd/system/getty@tty1.service.d

cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER_NAME --noclear %I \$TERM
EOF

### ===== .bash_profile автозапуск X =====
USER_HOME="/home/$USER_NAME"

cat > $USER_HOME/.bash_profile <<'EOF'
if [[ -z $DISPLAY ]] && [[ $(tty) == /dev/tty1 ]]; then
    startx
fi
EOF

chown $USER_NAME:$USER_NAME $USER_HOME/.bash_profile

### ===== XINIT =====
cat > $USER_HOME/.xinitrc <<EOF
#!/bin/bash

xset -dpms
xset s off
xset s noblank

unclutter -idle 0.1 -root &

openbox-session &

sleep 2

/usr/bin/chromium \
  --kiosk "$URL" \
  --noerrdialogs \
  --disable-infobars \
  --disable-session-crashed-bubble \
  --disable-features=TranslateUI \
  --disable-pinch \
  --overscroll-history-navigation=0 \
  --check-for-update-interval=31536000 \
  --simulate-outdated-no-au='Tue, 31 Dec 2099 23:59:59 GMT' &

### ===== СКРИПТ КОНТРОЛЯ СВЯЗИ =====
while true; do
    if ping -c1 -W1 $SERVER_IP >/dev/null; then
        xdotool search --name "NO_LINK" windowkill 2>/dev/null || true
    else
        if ! xdotool search --name "NO_LINK" >/dev/null 2>&1; then
            xmessage -center "Нет связи с климатическим компьютером

Нажмите ОБНОВИТЬ" \
            -buttons "Обновить:0" \
            -title "NO_LINK" &
        fi
    fi
    sleep 5
done
EOF

chmod +x $USER_HOME/.xinitrc
chown $USER_NAME:$USER_NAME $USER_HOME/.xinitrc

### ===== ОТКЛЮЧИТЬ SCREEN BLANKING =====
mkdir -p /etc/X11/xorg.conf.d

cat > /etc/X11/xorg.conf.d/10-monitor.conf <<EOF
Section "ServerFlags"
    Option "BlankTime" "0"
    Option "StandbyTime" "0"
    Option "SuspendTime" "0"
    Option "OffTime" "0"
EndSection
EOF

echo "=== DONE ==="
echo "Reboot system"
