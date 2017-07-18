### Администрирование:
При создании контракта администратором становиться ```sender```.
Добавить нового администратора может только действующий администратор.

### Получение информации из контракта:
1. Массив адресов администраторов (переменная ```admins(public)```).
2. Количество комнат (переменная ```idAndRoomWRSize(public)```).
3. Информация о размещении игрока (хэш таблица ```playerLocations(public. key = address, value = struct{uint idRoom, uint idTable})```).
4. Информация о комнатах (хэш таблица ```idAndRoomWR(public. key = id (uint), value = struct{uint id, uint countIdTable, uint betAmount, uint tableLifeTime, uint maxPlayers, uint numberPlayersOpenTable, uint tablesSize})```)

### Методы:
1. ```addAdmin(address)``` - добавить администратора.
2. ```createRoomWithRates(uint betAmount, uint tableLifeTime, uint maxPlayers, uint[] awards)``` - создать комнату.
3. ```putPlayerTable(uint idRoom) payable``` - посадить игрока за стол.
4. ```setResultPlayer(address player, uint result)``` - записать результат игрока.

### События:
1. При добавлении администратора инициируется событие ```AddAdmin(address)```.
2. При создании комнаты инициируется событие ```CreateRoomWithRates(uint idRoom, uint betAmount, uint tableLifeTime, uint maxPlayers)```.
3. При добавлении игрока за стол инициируется событие ```PutPlayerTable(address player, uint idRoom, uint idTable)```.
4. При закрытии стола(окончание игры) инициируется событие ```PayRewards(address player, uint value, uint place, uint idRoom, uint idTable)```.

