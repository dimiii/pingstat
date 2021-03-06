Основная идея
============

Для пингов с периодичностью `T` (=60 сек к примеру) весь массив ip aдресов разбивается на равные группы по числу секунд в периоде. В отдельном потоке каждую секунду все адреса в группе пингуются отправкой `ICMP` пакета через RAW сокет неблокирующим вызовом. В другом потоке через системный вызов `select` регистрируется прием ответов. Полученные данные о пинге сохраняются в очередь, чтобы потом пачками сохраняться в БД.

Иначе:
````
  PING-THREAD ↻          KERNEL              REPLY-THREAD ↻                      STORE-THREAD ↻       
  ~~~~~~~~~~~~~          ~~~~~~              ~~~~~~~~~~~~~~                      ~~~~~~~~~~~~~~              
 
[ip1 ... ipN] -> select (sock1 ... sockN)
~~~~~~~~~~~~                     ⚡ ->      обраб. icmp-ответа               
                                   ⚡ ->    ~~~~~~~~~~~~~~~~~~   -> ::Queue:: -> Пачкой из очереди в Redis
                                                                                ~~~~~~~~~~~~~~~~~~~~~~~~~
```

Т/к хосты могут долго молчать с ответом, а число дескрипторов на процесс не безгранично - периодически выполняется чистка подвисших сокетов.

В Linux по умолчанию `select` (процесс) поддерживает 1К файловых дескрипторов, так что если взять с резервом 500 пингов в секунду, ожидается что можно будет собирать данные по 30К хостам при ежеминутном опросе. Это, конечно, если три потока и ядро поделят эту секунду и справятся с задачами в выделенное время.


Ключевые параметры
===================
С помощью этих параметров можно настраивать производительность приложения (в зависимости от доли хостов с долгим пингом, нагрузки системы, близости хранилища).

* pingFrequency: 60 - в конструкторе PingDaemon
* taskTimeout: 5    - в конструкторе PingIO
* batchSize: 100    - в конструкторе InRedis
* ulimit -n         - в ОС


Тестирование и запуск
=====================

> pingstat user$ rspec spec/



> pingstat user$ ruby app/web.rb

Издержки решения
================

Из-за использования Raw сокетов, в Linux интерпретатор должен запускаться в режиме супер-пользователя или с установленными возможностями:
> <s>setcap CAP_NET_RAW+eip /usr/bin/ruby</s> - ???

В Mac OS X таких проблем нет.
