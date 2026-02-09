#!/bin/bash

set -e

echo "=== Установка kiosk режима ==="

KIOSK_URL_DEFAULT="http://192.168.202.206:5173/"
KIOSK_USER="user"

# --- пакеты ---
apt update
apt install -y \
    xorg \
    xinit \
    chromium \
    unclutter \
    curl \
    x11-xserver-utils

# --- папки ---
mkdir -p /opt/kiosk

# --- offline страница ---
cat >/opt/kiosk/offline.html <<'EOF'
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Нет связи</title>
<style>
body{
    margin:0;
    background:#111;
    color:#fff;
    font-family:Arial, sans-serif;
    display:flex;
    align-items:center;
    justify-content:center;
    height:100vh;
    text-align:center;
}
.box{
    max-width:600px;
}
h1{
    font-size:48px;
    margin-bottom:30px;
}
button{
    font-size:28px;
    padding:20px 40px;
    border:none;
    border-radius:10px;
    background:#2e7dff;
    color:white;
}
</style>
</head>
<body>
<div class="box">
<h1>Нет связи с климатическим компьютером</h1>
<button onclick="location.reload()">Обновить страницу</button>
</div>
</body>
</html>
EOF

# --- URL конфиг ---
if [ ! -f /etc/kiosk_url ]; then
    echo "$KIOSK_URL_DEFAULT" >/etc/kiosk_url
fi

# --- kiosk.sh ---
cat >/usr/local/bin/kiosk.sh <<'EOF'
#!/bin/bash

URL_FILE="/etc/kiosk_url"
DEFAULT_URL="http://192.168.202.206:5173/"
OFFLINE="/opt/kiosk/offline.html"

[ -f "$URL_FILE" ] && URL=$(cat $URL_FILE) || URL=$DEFAULT_URL

sleep 3

OUTPUT=$(xrandr | grep " connected" | head -n1 | cut -d" " -f1)
xrandr --output "$OUTPUT" --auto

xset -dpms
xset s off
xset s noblank

unclutter -idle 0 -root &

check_server() {
    curl -Is --max-time 3 "$URL" >/dev/null 2>&1
}

while true
do
    if check_server; then
        chromium \
            --kiosk \
            --start-maximized \
            --noerrdialogs \
            --disable-infobars \
            --disable-session-crashed-bubble \
            "$URL"
    else
        chromium \
            --kiosk \
            --start-maximized \
            "file://$OFFLINE"
    fi
    sleep 3
done
EOF

chmod +x /usr/local/bin/kiosk.sh

# --- .xinitrc ---
cat >/home/$KIOSK_USER/.xinitrc <<'EOF'
#!/bin/bash
exec /usr/local/bin/kiosk.sh
EOF

chmod +x /home/$KIOSK_USER/.xinitrc
chown $KIOSK_USER:$KIOSK_USER /home/$KIOSK_USER/.xinitrc

# --- автологин systemd ---
mkdir -p /etc/systemd/system/getty@tty1.service.d

cat >/etc/systemd/system/getty@tty1.service.d/autologin.conf <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $KIOSK_USER --noclear %I \$TERM
EOF

# --- автостарт X ---
cat >>/home/$KIOSK_USER/.bash_profile <<'EOF'

if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    startx
fi
EOF

chown $KIOSK_USER:$KIOSK_USER /home/$KIOSK_USER/.bash_profile

echo
echo "=== ГОТОВО ==="
echo "Перезагрузи систему:"
echo "reboot"
