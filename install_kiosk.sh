#!/bin/bash
set -e

KIOSK_URL="[http://192.168.202.206:5173/](http://192.168.202.206:5173/)"

echo "=== install packages ==="
apt-get update
apt-get install -y xorg openbox lightdm chromium unclutter curl

echo "=== create user ==="
id kiosk &>/dev/null || useradd -m -s /bin/bash kiosk
mkdir -p /home/kiosk/.config/openbox
chown -R kiosk:kiosk /home/kiosk

echo "=== save url ==="
cat > /etc/kiosk.conf <<EOF
KIOSK_URL="$KIOSK_URL"
EOF

echo "=== lightdm config ==="
cat > /etc/lightdm/lightdm.conf <<EOF
[Seat:*]
autologin-user=kiosk
autologin-session=openbox
xserver-command=X -nocursor -nolisten tcp
EOF

echo "=== openbox autostart ==="
cat > /home/kiosk/.config/openbox/autostart <<'EOF'
#!/bin/bash

source /etc/kiosk.conf

unclutter -idle 0 -root &

while true
do
echo "waiting for server $KIOSK_URL"
until curl -s --max-time 2 "$KIOSK_URL" > /dev/null; do
sleep 5
done

```
chromium \
    --kiosk "$KIOSK_URL" \
    --noerrdialogs \
    --disable-infobars \
    --disable-session-crashed-bubble \
    --disable-translate \
    --start-maximized

echo "chromium crashed → restart"
sleep 2
```

done
EOF

chmod +x /home/kiosk/.config/openbox/autostart
chown -R kiosk:kiosk /home/kiosk

echo "=== command to change url ==="
cat > /usr/local/bin/kiosk-set-url <<'EOF'
#!/bin/bash
if [ -z "$1" ]; then
echo "usage: kiosk-set-url [http://IP:PORT/](http://IP:PORT/)"
exit 1
fi

sudo sed -i "s|KIOSK_URL=.*|KIOSK_URL="$1"|" /etc/kiosk.conf
echo "URL changed to $1"
sudo systemctl restart lightdm
EOF

chmod +x /usr/local/bin/kiosk-set-url

echo "=== enable lightdm ==="
systemctl enable lightdm

echo
echo "INSTALL DONE"
echo "reboot system"
