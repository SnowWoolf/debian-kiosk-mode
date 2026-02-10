#!/bin/bash
set -e

echo "=== INSTALL KIOSK MODE ==="

export PATH=$PATH:/usr/sbin:/sbin:/bin:/usr/bin

USER_NAME=$(logname)
HOME_DIR="/home/$USER_NAME"

SERVER_IP="192.168.203.8"
URL="http://192.168.203.8"

apt update
apt install -y \
xorg xinit openbox chromium \
unclutter wmctrl xdotool \
fonts-dejavu-core locales

# locale
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen || true
/usr/sbin/locale-gen ru_RU.UTF-8
update-locale LANG=ru_RU.UTF-8

# отключаем sleep
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

# X настройки
mkdir -p /etc/X11/xorg.conf.d

cat >/etc/X11/xorg.conf.d/10-monitor.conf <<EOF
Section "ServerFlags"
 Option "BlankTime" "0"
 Option "StandbyTime" "0"
 Option "SuspendTime" "0"
 Option "OffTime" "0"
EndSection
EOF

# скрыть курсор полностью
cat >/etc/X11/xorg.conf.d/99-hide-cursor.conf <<EOF
Section "InputClass"
 Identifier "HideCursor"
 MatchIsPointer "on"
 Option "CursorVisible" "false"
EndSection
EOF

# overlay страница
mkdir -p /opt/kiosk

cat >/opt/kiosk/offline.html <<EOF
<html>
<head>
<meta charset="utf-8">
<style>
body {
 background:black;
 color:white;
 font-family:Arial;
 display:flex;
 align-items:center;
 justify-content:center;
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

# kiosk launcher
cat >/usr/local/bin/kiosk.sh <<EOF
#!/bin/bash

unclutter -idle 0.1 -root &

xset s off
xset -dpms
xset s noblank

while true
do
 if ping -c1 -W1 $SERVER_IP >/dev/null
 then
   chromium --kiosk --noerrdialogs --disable-infobars --disable-session-crashed-bubble "$URL"
 else
   chromium --kiosk --app=file:///opt/kiosk/offline.html
 fi
 sleep 2
done
EOF

chmod +x /usr/local/bin/kiosk.sh

# openbox autostart
mkdir -p $HOME_DIR/.config/openbox

cat >$HOME_DIR/.config/openbox/autostart <<EOF
/usr/local/bin/kiosk.sh
EOF

chown -R $USER_NAME:$USER_NAME $HOME_DIR/.config

# xinit
cat >$HOME_DIR/.xinitrc <<EOF
exec openbox-session
EOF

chown $USER_NAME:$USER_NAME $HOME_DIR/.xinitrc

# автозапуск X
cat >$HOME_DIR/.bash_profile <<EOF
if [ -z "\$DISPLAY" ] && [ "\$(tty)" = "/dev/tty1" ]; then
 startx
fi
EOF

chown $USER_NAME:$USER_NAME $HOME_DIR/.bash_profile

# автологин
mkdir -p /etc/systemd/system/getty@tty1.service.d

cat >/etc/systemd/system/getty@tty1.service.d/autologin.conf <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER_NAME --noclear %I \$TERM
EOF

echo
echo "=== READY ==="
echo "reboot"
/sbin/reboot
