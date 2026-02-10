#!/bin/bash

# ===== НАСТРОЙКИ =====
SERVER_IP="192.168.203.86"
URL="http://192.168.203.86:8080"
USER_NAME="user"

# ===== УСТАНОВКА ПАКЕТОВ =====
apt update
apt install -y \
  chromium \
  xorg \
  xinit \
  openbox \
  unclutter \
  feh \
  fonts-dejavu \
  curl

mkdir -p /opt/kiosk

# ===== OFFLINE СТРАНИЦА =====
cat >/opt/kiosk/offline.html <<EOF
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
body {
  background:black;
  color:white;
  font-family:sans-serif;
  display:flex;
  justify-content:center;
  align-items:center;
  height:100vh;
  flex-direction:column;
}
button {
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

# ===== СКРИПТ ЗАПУСКА KIOSK =====
cat >/opt/kiosk/start.sh <<EOF
#!/bin/bash

xset -dpms
xset s off
xset s noblank

unclutter -idle 0 &

while true
do
  if ping -c1 -W1 $SERVER_IP >/dev/null
  then
    chromium \
      --kiosk \
      --noerrdialogs \
      --disable-infobars \
      --disable-session-crashed-bubble \
      --disable-restore-session-state \
      --disable-features=TranslateUI \
      --overscroll-history-navigation=0 \
      $URL
  else
    chromium --kiosk file:///opt/kiosk/offline.html
  fi

  sleep 2
done
EOF

chmod +x /opt/kiosk/start.sh

# ===== .xinitrc =====
cat >/home/$USER_NAME/.xinitrc <<EOF
#!/bin/bash
exec openbox-session &
sleep 1
/opt/kiosk/start.sh
EOF

chmod +x /home/$USER_NAME/.xinitrc
chown $USER_NAME:$USER_NAME /home/$USER_NAME/.xinitrc

# ===== АВТОЛОГИН tty1 =====
mkdir -p /etc/systemd/system/getty@tty1.service.d

cat >/etc/systemd/system/getty@tty1.service.d/autologin.conf <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER_NAME --noclear %I \$TERM
EOF

# ===== АВТОСТАРТ X =====
cat >>/home/$USER_NAME/.bash_profile <<'EOF'

if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
  startx
  logout
fi
EOF

chown $USER_NAME:$USER_NAME /home/$USER_NAME/.bash_profile

# ===== ОТКЛЮЧАЕМ DISPLAY MANAGER =====
systemctl set-default multi-user.target

echo "ГОТОВО. Перезагрузка..."
sleep 2
/sbin/reboot
