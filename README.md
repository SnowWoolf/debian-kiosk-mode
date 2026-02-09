# Установка режима киоска

```shell
wget -qO- https://raw.githubusercontent.com/SnowWoolf/debian-kiosk-mode/main/install_kiosk.sh | bash
```


---
---


# Работа с киоском (через терминал с подключенной клавиатурой)

## Открыть консоль
В режиме киоска:
```
Ctrl + Alt + F3
```
Войти под пользователем с sudo.

---

## Узнать IP терминала
```
ip a
```
Смотрим интерфейс `eth0` или `wlan0`, строка `inet`.

---

## Поменять адрес сайта (URL киоска)
Используется служебная команда:
```
sudo kiosk-set-url http://IP:PORT/
```

Пример:
```
sudo kiosk-set-url http://192.168.1.100:8080/
```

После выполнения:
```
reboot
```

---

## Задать статический IP

Открыть конфиг сети:
```
sudo nano /etc/network/interfaces
```

Пример:
```
auto eth0
iface eth0 inet static
address 192.168.1.50
netmask 255.255.255.0
gateway 192.168.1.1
dns-nameservers 8.8.8.8
```

Сохранить и применить:
```
sudo systemctl restart networking
```
или:
```
reboot
```
