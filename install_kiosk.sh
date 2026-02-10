#!/bin/bash

TARGET_URL="http://192.168.203.86:8080"
USER_NAME="user"

echo "=== Установка kiosk режима ==="

apt update
apt install -y chromium unclutter xdotool

# автологин в tty1
mkdir -p /etc/systemd/system/getty@tty1.service.d

cat >/etc/systemd/system/getty@tty1.service.d/autologin.conf <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER_NAME --noclear %I \$TERM
EOF

# автозапуск X
cat >/home/$USER_NAME/.bash_profile <<'EOF'
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
  startx
fi
EOF

chown $USER_NAME:$USER_NAME /home/$USER_NAME/.bash_profile

# .xinitrc
cat >/home/$USER_NAME/.xinitrc <<'EOF'
#!/bin/bash

xset -dpms
xset s off
xset s noblank
unclutter -idle 0 &

OFFLINE="/home/user/offline.html"
URL="http://192.168.203.86:8080"

while true; do

  if ping -c1 -W1 192.168.203.86 >/dev/null; then
      chromium \
        --kiosk \
        --start-fullscreen \
        --start-maximized \
        --noerrdialogs \
        --disable-infobars \
        --disable-session-crashed-bubble \
        --disable-features=TranslateUI \
        --overscroll-history-navigation=0 \
        "$URL"
  else
      chromium \
        --kiosk \
        --start-fullscreen \
        --app="$OFFLINE"
  fi

  sleep 2
done
EOF

chmod +x /home/$USER_NAME/.xinitrc
chown $USER_NAME:$USER_NAME /home/$USER_NAME/.xinitrc

# оффлайн страница
cat >/home/$USER_NAME/offline.html <<'EOF'
<html>
<head>
<meta charset="utf-8">
<style>
body {
  background:black;
  color:white;
  font-family:Arial;
  text-align:center;
  margin-top:20%;
  font-size:40px;
}
</style>
<script>
setInterval(()=>{
  fetch("http://192.168.203.86:8080",{mode:"no-cors"})
    .then(()=>location.reload())
    .catch(()=>{});
},2000);
</script>
</head>
<body>
НЕТ СВЯЗИ
</body>
</html>
EOF

chown $USER_NAME:$USER_NAME /home/$USER_NAME/offline.html

echo "=== Готово. Перезагрузи систему ==="
