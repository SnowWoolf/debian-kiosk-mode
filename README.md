# Установка режима киоска

```shell
wget https://raw.githubusercontent.com/SnowWoolf/kiosk/refs/heads/main/install_kiosk.sh; chmod +x install_kiosk.sh; bash install_kiosk.sh
```


# Краткая инструкция по работе с киоском (через терминал с подключенной клавиатурой)

## Открыть консоль
В режиме киоска:
```
Ctrl + Alt + F3
```
Войти под пользователем (обычно `root`).

---

## Узнать IP терминала
```
ip a
```
Ищем интерфейс `eth0` или `wlan0`, строка `inet`.

---

## Поменять адрес сайта (URL киоска)
Открыть конфиг автозапуска (пример):
```
nano /home/user/.config/autostart/kiosk.desktop
```
или:
```
nano /etc/xdg/autostart/kiosk.desktop
```

Найти строку с браузером:
```
Exec=chromium-browser --kiosk http://OLD_ADDRESS
```
Заменить на:
```
Exec=chromium-browser --kiosk http://NEW_ADDRESS
```

Сохранить:
```
Ctrl+O → Enter → Ctrl+X
```

Перезагрузка:
```
reboot
```

---

## Задать статический IP

Открыть конфиг сети (Debian/Ubuntu):
```
nano /etc/network/interfaces
```

Пример статического IP:
```
auto eth0
iface eth0 inet static
address 192.168.1.50
netmask 255.255.255.0
gateway 192.168.1.1
dns-nameservers 8.8.8.8
```

Сохранить и перезапустить сеть:
```
systemctl restart networking
```
или перезагрузка:
```
reboot
```
