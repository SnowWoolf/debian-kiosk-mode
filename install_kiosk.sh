#!/bin/bash
set -e

KIOSK_URL="[http://192.168.202.206:5173/](http://192.168.202.206:5173/)"

echo "Installing packages..."
apt-get update
apt-get install -y xorg openbox lightdm chromium unclutter xdotool curl openssh-server

systemctl enable ssh

echo "Creating user..."
id kiosk &>/dev/null || useradd -m -s /bin/bash kiosk
mkdir -p /home/kiosk/.config/openbox
chown -R kiosk:kiosk /home/kiosk

echo "Writing config..."
cat > /etc/kiosk.conf <<EOF
KIOSK_URL="$KIOSK_URL"
EOF

echo "LightDM config..."
cat > /etc/lightdm/lightdm.conf <<EOF
[Seat:*]
autologin-user=kiosk
autologin-session=openbox
xserver-command=X -nocursor -nolisten tcp
EOF

echo "Openbox autostart..."
cat > /home/kiosk/.config/openbox/autostart <<'EOF'
#!/bin/bash

setxkbmap -option terminate:ctrl_alt_bksp
unclutter -idle 0 -root &

systemctl --user start kiosk.service
EOF

chown kiosk:kiosk /home/kiosk/.config/openbox/autostart
chmod +x /home/kiosk/.config/openbox/autostart

echo "Systemd user service..."
mkdir -p /home/kiosk/.config/systemd/user

cat > /home/kiosk/.config/systemd/user/kiosk.service <<'EOF'
[Unit]
Description=Kiosk Browser
After=graphical-session.target

[Service]
ExecStart=/usr/local/bin/kiosk.sh
Restart=always

[Install]
WantedBy=default.target
EOF

chown -R kiosk:kiosk /home/kiosk/.config/systemd

echo "Watchdog script..."
cat > /usr/local/bin/kiosk.sh <<'EOF'
#!/bin/bash
source /etc/kiosk.conf

while true
do
until curl -s --max-time 2 "$KIOSK_URL" > /dev/null; do
echo "Waiting for server..."
sleep 5
done

chromium 
--kiosk "$KIOSK_URL" 
--noerrdialogs 
--disable-infobars 
--disable-session-crashed-bubble 
--disable-translate 
--start-maximized

echo "Chromium crashed. Restarting..."
sleep 2
done
EOF

chmod +x /usr/local/bin/kiosk.sh

echo "Command to change URL..."
cat > /usr/local/bin/kiosk-set-url <<'EOF'
#!/bin/bash
if [ -z "$1" ]; then
echo "usage: kiosk-set-url [http://IP:PORT/](http://IP:PORT/)"
exit 1
fi

sudo sed -i "s|KIOSK_URL=.*|KIOSK_URL="$1"|" /etc/kiosk.conf
sudo systemctl restart lightdm
EOF

chmod +x /usr/local/bin/kiosk-set-url

echo "Enabling user service..."
sudo -u kiosk systemctl --user daemon-reload || true

echo "Done. Reboot now."
