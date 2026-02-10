sudo nano /opt/kiosk/start.sh


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



sudo chmod +x /opt/kiosk/start.sh
