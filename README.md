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

**Отключить баннер переводчика chrome:**
mkdir -p /etc/chromium/policies/managed
nano /etc/chromium/policies/managed/kiosk.json
Вставить:
```
{
  "TranslateEnabled": false,
  "TranslateUIEnabled": false,
  "DefaultTranslateSetting": 2
}
```
Это полностью отключает переводчик на уровне политики.


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

С правами su:
```
kiosk-set-url http://192.168.203.200:8080"
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

