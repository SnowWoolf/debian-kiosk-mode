# Debian Kiosk Mode

# УСТАНОВКА

Установить Debian без окружения рабочего стола (только SSH-сервер и стандартные системные утилиты)
Во время установки создать пользователя **user**


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

# СМЕНИТЬ АДРЕС ОТОБРАЖАЕМОЙ СТРАНИЦЫ

```
NEW="http://192.168.203.200:8080"
sed -i "s|URL=\".*\"|URL=\"$NEW\"|" /home/user/.xinitrc
sed -i "s|fetch(\".*\"|fetch(\"$NEW\"|" /home/user/offline.html
/sbin/reboot
```



---

# ЗАДАТЬ СТАТИЧЕСКИЙ IP

```

```


---

# ПЕРЕЗАГРУЗКА

```
/sbin/reboot
```

