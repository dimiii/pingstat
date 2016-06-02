Приложение имеет следующие вызовы:
1) Добавить IP-адрес к подсчету статистики (параметр - IP-адрес, нотацию выбери сам)
2) Удалить IP-адрес из подсчета статистики (параметр - IP-адрес, нотацию выбери сам)
3) Сообщить статистику доступности IP-адреса по ICMP [то есть посредством ping] (параметры - IP-адрес, начало интервала времени, конец интервала времени). Получив начало и конец интервала времени, должно вернуть JSON, содержащий следующие поля:
        - среднее RTT (время отклика на пинг) за этот период
        - минимальное RTT за этот период
        - максимальное RTT за этот период
        - медианное RTT за этот период
        - среднеквадратичное отклонение замеров RTT за этот период
        - процент потерянных пакетов ICMP (ping) до указанного адреса за этот период.

Если какую-то часть времени в этом периоде IP-адрес был вне расчета статистики (не был добавлен или был удален) - эту часть времени учитывать не нужно. Например, мы добавили ip-адрес 8.8.8.8 в 1 час, выключили в 2, включили в 3 и выключили в 4. Если я запросил статистику с 1 по 4 часа — надо объединить интервалы 1-2, 3-4 и отдать эту статистику по объединенному интервалу. Если IP-адрес не был в расчете статистики все время или был настолько мало времени, что мы не успели сделать хотя бы 1 замер - надо вернуть сообщение об ошибке.

Соответственно, удаленные машины, имеющие IP-адреса из этого списка могут вести себя очень странно - не отвечать на пинги, отвечать с ооочень большой задержкой - например, минуту (если захочется поиграться с этим случаем, его можно смоделировать на машинке, поставив, например, Charles http://www.charlesproxy.com/documentation/proxying/throttling/ туда).

Задание может быть выполнено на разном уровне сложности - можно замахнуться на то, чтобы сделать идеально и таки научиться обрабатывать ситуации с пингом в минуту, или пытаться оптимизировать производительность - а можно не делать ничего из этого. Ты можешь пойти любым путем в зависимости от твоего свободного времени.


