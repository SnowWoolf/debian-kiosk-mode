# Debian Kiosk Mode

# УСТАНОВКА

Установить Debian без окружения рабочего стола (только SSH)
Выполнить:

```
wget -qO- https://raw.githubusercontent.com/SnowWoolf/debian-kiosk-mode/main/install_kiosk.sh | bash
```

После завершения:
```
/sbin/reboot
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
ip a
```

---

# СМЕНИТЬ АДРЕС САЙТА КИОСКА

```
sed -i 's|URL=".*"|URL="http://IP:PORT/"|' /home/user/.xinitrc
```

пример:
```
sed -i 's|URL=".*"|URL="http://192.168.1.50:8080"|' /home/user/.xinitrc
```

затем перезапустить chrome:
```
pkill chromium
```
ну или перезагрузить терминал.


---

# ЗАДАТЬ СТАТИЧЕСКИЙ IP

```

```


---

# ПЕРЕЗАГРУЗКА

```
/sbin/reboot
```

