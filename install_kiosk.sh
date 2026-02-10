#!/bin/bash

set -e

echo "=== Установка kiosk режима ==="

KIOSK_USER="user"
KIOSK_URL_FILE="/etc/kiosk-url"
DEFAULT_URL="http://localhost:80/"

# 1. Пакеты
apt update
apt install -y --no-install-recommends \
    xserver-xorg \
    x11-xserver-utils \
    xinit \
    openbox \
    chromium \
    unclutter \
    wget

# 2. Файл URL
if [ ! -f "$KIOSK_URL_FILE" ]; then
    echo "$DEFAULT_URL" > "$KIOSK_URL_FILE"
fi

# 3. Скрипт запуска браузера
cat > /usr/local/bin/kiosk-start <<'EOF'
#!/bin/bash

URL=$(cat /etc/kiosk-url)

while true; do
    ping -c1 -W1 8.8.8.8 >/dev/null 2>&1 && break
    echo "Нет сети, ждём..."
    sleep 2
done

unclutter -idle 0 &
chromium \
  --kiosk \
  --noerrdialogs \
  --disable-infobars \
  --disable-session-crashed-bubble \
  --disable-features=TranslateUI \
  --check-for-update-interval=31536000 \
  "$URL"
EOF

chmod +x /usr/local/bin/kiosk-start

# 4. Команда смены URL
cat > /usr/local/bin/kiosk-set-url <<'EOF'
#!/bin/bash

if [ -z "$1" ]; then
  echo "Использование: kiosk-set-url http://IP:PORT/"
  exit 1
fi

echo "$1" > /etc/kiosk-url
echo "URL изменён на $1"
reboot
EOF

chmod +x /usr/local/bin/kiosk-set-url

# 5. autologin systemd override
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $KIOSK_USER --noclear %I \$TERM
EOF

# 6. автозапуск X
USER_HOME="/home/$KIOSK_USER"

cat > "$USER_HOME/.bash_profile" <<'EOF'
if [[ -z $DISPLAY ]] && [[ $(tty) == /dev/tty1 ]]; then
    startx
fi
EOF

# 7. xinitrc
cat > "$USER_HOME/.xinitrc" <<'EOF'
xset -dpms
xset s off
xset s noblank
/usr/local/bin/kiosk-start
EOF

chown $KIOSK_USER:$KIOSK_USER "$USER_HOME/.bash_profile"
chown $KIOSK_USER:$KIOSK_USER "$USER_HOME/.xinitrc"

echo "=== Готово ==="
echo "Команда смены адреса:"
echo "kiosk-set-url http://IP:PORT/"
echo
echo "Перезагружаю..."
sleep 2
reboot
