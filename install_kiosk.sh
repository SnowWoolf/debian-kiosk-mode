#!/bin/bash
set -e

USER_NAME=${SUDO_USER:-user}
HOME_DIR="/home/$USER_NAME"
URL="http://192.168.203.86:8080"

echo "INSTALL PACKAGES"
apt update
apt install -y chromium unclutter wmctrl xdotool

echo "DISABLE SLEEP"
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

echo "DISABLE KEYRING"
apt purge -y gnome-keyring seahorse || true
rm -rf $HOME_DIR/.local/share/keyrings

echo "CREATE OFFLINE PAGE"

cat >/opt/kiosk_offline.html <<EOF
<html>
<head>
<meta charset="utf-8">
<style>
body{
background:#111;
color:white;
font-family:Arial;
display:flex;
flex-direction:column;
align-items:center;
justify-content:center;
height:100vh;
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

echo "CREATE KIOSK SCRIPT"

cat >/usr/local/bin/kiosk.sh <<'EOF'
#!/bin/bash

URL_FILE="/etc/kiosk_url"
DEFAULT_URL="http://192.168.203.86:8080"

[ -f "$URL_FILE" ] && URL=$(cat $URL_FILE) || URL=$DEFAULT_URL

xset s off
xset -dpms
xset s noblank
xsetroot -cursor_name left_ptr
unclutter -idle 0 -root &

sleep 2

chromium \
 --kiosk \
 --noerrdialogs \
 --disable-infobars \
 --disable-session-crashed-bubble \
 --disable-translate \
 --overscroll-history-navigation=0 \
 --disable-pinch \
 "$URL" &

sleep 5

while true
do
 if ! ping -c1 -W1 $(echo $URL | cut -d/ -f3 | cut -d: -f1) >/dev/null
 then
   wmctrl -a Chromium
   xdotool key Ctrl+l
   xdotool type "file:///opt/kiosk_offline.html"
   xdotool key Return
   sleep 5
 fi

 sleep 5
done
EOF

chmod +x /usr/local/bin/kiosk.sh

echo "AUTOSTART XFCE"

mkdir -p $HOME_DIR/.config/autostart

cat >$HOME_DIR/.config/autostart/kiosk.desktop <<EOF
[Desktop Entry]
Type=Application
Exec=/usr/local/bin/kiosk.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Kiosk
EOF

chown -R $USER_NAME:$USER_NAME $HOME_DIR/.config

echo "URL COMMAND"

cat >/usr/local/bin/kiosk-set-url <<'EOF'
#!/bin/bash
echo "$1" | sudo tee /etc/kiosk_url
EOF
chmod +x /usr/local/bin/kiosk-set-url

echo "DONE"
echo "REBOOT REQUIRED"
