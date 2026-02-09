#!/bin/bash
set -e

KIOSK_URL="http://192.168.203.8"   # <-- адрес климатического ПК

echo "== Установка kiosk режима =="

apt update
apt install -y \
    xorg \
    openbox \
    chromium \
    unclutter \
    x11-xserver-utils \
    wget \
    curl

mkdir -p /opt/kiosk
mkdir -p /home/user/.config/openbox
mkdir -p /home/user/.config/chromium

############################################
# HTML заглушка при отсутствии сервера
############################################
cat >/opt/kiosk/offline.html <<EOF
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta http-equiv="refresh" content="10">
<style>
body{
background:#000;
color:#fff;
font-family:Arial;
display:flex;
justify-content:center;
align-items:center;
height:100vh;
flex-direction:column;
}
button{
font-size:30px;
padding:20px 40px;
margin-top:40px;
}
</style>
</head>
<body>
<h1>Нет связи с климатическим компьютером</h1>
<button onclick="location.reload()">Обновить страницу</button>
</body>
</html>
EOF

############################################
# KIOSK SCRIPT
############################################
cat >/usr/local/bin/kiosk.sh <<'EOF'
#!/bin/bash

URL="http://192.168.203.8"

# Ждём X
sleep 2

# Определяем дисплей
DISPLAY=:0
export DISPLAY

# Берём первый подключенный монитор
MON=$(xrandr | grep " connected" | head -n1 | cut -d" " -f1)

# Ставим нативное разрешение
MODE=$(xrandr | grep "*" | head -n1 | awk '{print $1}')
xrandr --output "$MON" --mode "$MODE"

# Убираем энергосбережение
xset s off
xset -dpms
xset s noblank

# Прячем курсор
unclutter -idle 0 -root &

while true; do

    if ping -c1 -W1 192.168.203.8 >/dev/null; then
        chromium \
          --kiosk \
          --noerrdialogs \
          --disable-infobars \
          --disable-session-crashed-bubble \
          --disable-restore-session-state \
          --incognito \
          --start-fullscreen \
          --window-position=0,0 \
          --window-size=1920,1080 \
          "$URL"
    else
        chromium \
          --kiosk \
          --incognito \
          --start-fullscreen \
          file:///opt/kiosk/offline.html
    fi

    sleep 2
done
EOF

chmod +x /usr/local/bin/kiosk.sh

############################################
# Openbox autostart
############################################
cat >/home/user/.config/openbox/autostart <<EOF
/usr/local/bin/kiosk.sh
EOF

chown -R user:user /home/user/.config

############################################
# .xinitrc
############################################
cat >/home/user/.xinitrc <<EOF
exec openbox-session
EOF

chown user:user /home/user/.xinitrc

############################################
# Автостарт X
############################################
cat >/etc/systemd/system/kiosk.service <<EOF
[Unit]
Description=Kiosk
After=systemd-user-sessions.service

[Service]
User=user
Environment=DISPLAY=:0
ExecStart=/usr/bin/startx
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reexec
systemctl enable kiosk.service

echo
echo "===== ГОТОВО ====="
echo "Перезагрузи систему:"
echo "reboot"
