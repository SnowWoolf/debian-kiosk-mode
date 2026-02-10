#!/bin/bash
set -e

echo "=== INSTALL KIOSK MODE ==="

USER_NAME=${SUDO_USER:-$(logname)}
HOME_DIR="/home/$USER_NAME"

export DEBIAN_FRONTEND=noninteractive

apt update
apt install -y \
xorg \
xinit \
openbox \
chromium \
unclutter \
curl \
fonts-dejavu-core

############################################
# URL файл
############################################
echo "http://192.168.0.100/" >/etc/kiosk_url

############################################
# страница offline
############################################
cat >/usr/local/share/kiosk-offline.html <<'EOF'
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Нет связи</title>
<style>
body{
background:#111;
color:#fff;
font-family:Arial;
display:flex;
justify-content:center;
align-items:center;
height:100vh;
flex-direction:column;
}
button{
font-size:28px;
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
# kiosk.sh
############################################
cat >/usr/local/bin/kiosk.sh <<'EOF'
#!/bin/bash

URL=$(cat /etc/kiosk_url)

sleep 2

xset s off
xset -dpms
xset s noblank

unclutter -idle 0 -root &

while true
do
    if curl -s --max-time 3 "$URL" >/dev/null; then
        chromium \
        --kiosk \
        --start-fullscreen \
        --noerrdialogs \
        --disable-infobars \
        --disable-session-crashed-bubble \
        --disable-translate \
        "$URL"
    else
        chromium \
        --kiosk \
        --start-fullscreen \
        file:///usr/local/share/kiosk-offline.html
    fi

    sleep 2
done
EOF

chmod +x /usr/local/bin/kiosk.sh

############################################
# команда смены URL
############################################
cat >/usr/local/bin/kiosk-set-url <<'EOF'
#!/bin/bash
echo "$1" | sudo tee /etc/kiosk_url
echo "URL изменён. Перезагрузка..."
sudo reboot
EOF
chmod +x /usr/local/bin/kiosk-set-url

############################################
# openbox autostart
############################################
mkdir -p $HOME_DIR/.config/openbox

cat >$HOME_DIR/.config/openbox/autostart <<'EOF'
/usr/local/bin/kiosk.sh
EOF

chown -R $USER_NAME:$USER_NAME $HOME_DIR/.config

############################################
# xinitrc
############################################
cat >$HOME_DIR/.xinitrc <<'EOF'
exec openbox-session
EOF
chown $USER_NAME:$USER_NAME $HOME_DIR/.xinitrc

############################################
# автозапуск X
############################################
cat >$HOME_DIR/.bash_profile <<'EOF'
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
startx
fi
EOF
chown $USER_NAME:$USER_NAME $HOME_DIR/.bash_profile

############################################
# автологин tty1
############################################
mkdir -p /etc/systemd/system/getty@tty1.service.d

cat >/etc/systemd/system/getty@tty1.service.d/autologin.conf <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER_NAME --noclear %I \$TERM
EOF

############################################
echo
echo "=== ГОТОВО ==="
echo "Перезагружаю..."
sleep 2
/sbin/reboot
