apt update
apt install -y xorg xinit openbox chromium unclutter fonts-dejavu-core

USER_NAME="user"
HOME_DIR="/home/$USER_NAME"

mkdir -p /opt/kiosk
echo "https://allmonitoring.ru/" > /opt/kiosk/url

# ---------- OFFLINE PAGE ----------
cat > /opt/kiosk/offline.html <<'EOF'
<html>
<head>
<meta charset="utf-8">
<style>
body{
background:#111;
color:#fff;
font-family:Arial;
display:flex;
align-items:center;
justify-content:center;
height:100vh;
flex-direction:column;
}
button{
font-size:32px;
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

# ---------- START SCRIPT ----------
cat > /opt/kiosk/start.sh <<'EOF'
#!/bin/bash

xset -dpms
xset s off
xset s noblank

unclutter -idle 0 -root &

URL=$(cat /opt/kiosk/url)
SERVER=$(echo $URL | awk -F/ '{print $3}' | cut -d: -f1)

open_chrome () {
  chromium \
  --kiosk "$1" \
  --start-fullscreen \
  --noerrdialogs \
  --disable-infobars \
  --disable-session-crashed-bubble \
  --disable-translate \
  --disable-features=TranslateUI \
  --disable-component-extensions-with-background-pages \
  --overscroll-history-navigation=0 &
}

pkill chromium
sleep 2

open_chrome "$URL"

STATE="online"

while true
do
  if ping -c1 -W1 "$SERVER" >/dev/null 2>&1; then
      if [ "$STATE" = "offline" ]; then
          pkill chromium
          sleep 2
          open_chrome "$URL"
          STATE="online"
      fi
  else
      if [ "$STATE" = "online" ]; then
          pkill chromium
          sleep 2
          open_chrome "file:///opt/kiosk/offline.html"
          STATE="offline"
      fi
  fi

  sleep 3
done
EOF

chmod +x /opt/kiosk/start.sh

# ---------- OPENBOX ----------
mkdir -p $HOME_DIR/.config/openbox

cat > $HOME_DIR/.config/openbox/autostart <<'EOF'
/opt/kiosk/start.sh &
EOF

cat > $HOME_DIR/.xinitrc <<'EOF'
exec openbox-session
EOF

cat > $HOME_DIR/.bash_profile <<'EOF'
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
startx
fi
EOF

chown -R $USER_NAME:$USER_NAME $HOME_DIR

# ---------- AUTOLOGIN ----------
mkdir -p /etc/systemd/system/getty@tty1.service.d

cat > /etc/systemd/system/getty@tty1.service.d/override.conf <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER_NAME --noclear %I \$TERM
EOF

# ---------- CHANGE URL ----------
cat > /usr/local/bin/kiosk-set-url <<'EOF'
#!/bin/bash
echo "$1" > /opt/kiosk/url
/sbin/reboot
EOF

chmod +x /usr/local/bin/kiosk-set-url

echo
echo "ГОТОВО. ПЕРЕЗАГРУЗКА...."
/sbin/reboot
