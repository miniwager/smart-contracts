### Администрирование:
При создании контракта администратором становиться ```sender```.
Добавить нового администратора может только действующий администратор.

### Получение информации из контракта:
1. Массив адресов администраторов (переменная ```admins(public)```).
2. Доля от суммы стола (награда) (хэш-таблица ```awardsPlace(public. key = idRoom (uint), value = (uint[]))```).
3. Информация о игроке (```playersAndResult(uint idRoom, uint idTable, address addrPlayer) return(GameInfoPlayer{bool setResult, uint result, uint reward, bool created})```).
4. Информация о столе (```idRoomIdTableAndTable(uint idRoom, uint idTable) return(Table{uint id, uint closingTime, uint bank})```).
5. Информация о комнате (хэш-таблица ```idRoomAndRoomWR(public. key = id (uint), value = RoomWithRates{uint id, uint countIdTable, uint betAmount, uint tableLifeTime, uint maxPlayers, uint numberPlayersOpenTable, uint fee})```).
6. Расположение игрока (```хэш-таблица playerLocations(public. key = addrPlayer(address), value = playerLocations{uint idRoom, uint idTable})```).

### Методы:
1. ```addAdmin(address)``` - добавить администратора.
2. ```createRoomWithRates(uint betAmount, uint tableLifeTime, uint maxPlayers, uint fee, uint[] awards)``` - создать комнату.
3. ```putPlayerTable(uint idRoom) payable``` - посадить игрока за стол.
4. ```setResultPlayer(address player, uint result)``` - записать результат игрока.
5. ```deleteRoom(uint idRoom)``` - удалить комнату.

### События:
1. При добавлении администратора инициируется событие ```AddAdmin(address)```.
2. При создании комнаты инициируется событие ```CreateRoomWithRates(uint id, uint betAmount, uint tableLifeTime, uint maxPlayers, uint fee)```.
3. При добавлении игрока за стол инициируется событие ```PutPlayerTable(address player, uint idRoom, uint idTable)```.
4. При закрытии стола(окончание игры) инициируется событие ```PayRewards(address player, uint value, uint place, uint idRoom, uint idTable)```.
5. При удалении комнаты инициируется событие ```DeleteRoom(uint idRoom)```.

