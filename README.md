# Debian Kiosk Mode

Минимальный киоск-режим для Debian 11/12/13.  
Автозапуск Chromium в fullscreen, без сна и гашения экрана.  
Управление полностью из терминала с подключённой клавиатуры.

---

# УСТАНОВКА

Выполнить на чистой системе Debian:

```
wget -qO- https://raw.githubusercontent.com/SnowWoolf/debian-kiosk-mode/main/install_kiosk.sh | bash
```

После завершения:
```
reboot
```

Терминал автоматически загрузится в киоск.

---

# ОТКРЫТЬ ТЕРМИНАЛ С КЛАВИАТУРЫ

```
Ctrl + Alt + F3
```

Вернуться в киоск:
```
Ctrl + Alt + F1
```

---

# УЗНАТЬ IP ТЕРМИНАЛА

```
kiosk-ip
```

или
```
ip a
```

---

# СМЕНИТЬ АДРЕС САЙТА КИОСКА

```
sudo kiosk-set-url http://IP:PORT/
```

пример:
```
sudo kiosk-set-url http://192.168.202.206:5173/
```

затем:
```
reboot
```

---

# ЗАДАТЬ СТАТИЧЕСКИЙ IP

```
sudo kiosk-set-static-ip 192.168.1.50 192.168.1.1
reboot
```

где  
`192.168.1.50` — IP терминала  
`192.168.1.1` — шлюз  

DNS по умолчанию: 8.8.8.8

---

# ПЕРЕЗАГРУЗКА

```
/sbin/reboot
```

