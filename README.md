### Загрузка контракта:
В первую очередь загружается контракт с наградами.
При загрузке контракта конструктор принимает комиссию, адрес контракта с наградами и адрес сервера. Если адрес сервера не передан сервером будет ```sender```.

### Администрирование:
При создании контракта администратором становиться ```sender```.
Добавить нового администратора может только действующий администратор.

### Получение информации из контракта:
1. Массив адресов администраторов (переменная ```admins(public)```).
2. Адрес сервера (переменная ```serverAddress(public)```).
3. Информация о комнате (хэш-таблица ```rooms(public. key = idRoom (uint), value = {uint countIdTable, uint betAmount, uint maxPlayers, uint fee, uint[] awards, uint lastBusyTable})```).
4. Информайия о столе (хэш-таблица ```tables(uint idRoom, uint idTable) return(address[])```).
5. Информация о игроке (хэш-таблица ```results(uint idRoom, uint idTable, address player) return(InformationsPlayer{bool status, uint result})```).

### Методы:
1. ```addAdmin(address)``` - добавить администратора.
2. ```changeServerAddr(address newAddress)``` - изменить адрес сервера.
3. ```setFee(uint _fee)``` - изменить комиссию.
4. ```createRoomWithRates(uint betAmount, uint maxPlayers, uint[] awards)``` - создать комнату.
5. ```putPlayerTableRoomWR(uint idRoom) payable``` - посадить игрока за стол.
6. ```setResultPlayer(address player, uint idRoom, uint idTable, uint result)``` - записать результат игрока.
7. ```deleteRoom(uint idRoom)``` - удалить комнату.
8. ```setAwards(address newAwards)``` - изменить награды.

### События:
1. При добавлении администратора инициируется событие ```AddAdmin(address)```.
2. При создании комнаты инициируется событие ```CreateRoomWithRates(uint id, uint betAmount, uint maxPlayers)```.
3. При добавлении игрока за стол инициируется событие ```PutPlayerTable(address player, uint idRoom, uint idTable)```.
4. При закрытии стола(окончание игры) инициируется событие ```PayRewards(address player, uint value, uint place, uint idRoom, uint idTable)```.
5. При удалении комнаты инициируется событие ```DeleteRoom(uint idRoom)```.
6. При установке комиссии ```SetFee(uint oldFee, uint newFee)```.
7. При установке наград ```SetAwards(address oldAwards, address newAwards)```.
