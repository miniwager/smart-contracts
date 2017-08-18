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
4. ```setAwards(address newAwards)``` - изменить вознаграждение.
5. ```createRoomWithRates(uint betAmount, uint maxPlayers, uint[] awards)``` - создать комнату со ставками.
6. ```createRoomWithoutBets(uint roomLifeTime) payable``` - создать комнату без ставок.
7. ```putPlayerTable(uint idRoom) payable``` - посадить игрока за стол.
8. ```setResultPlayer(address player, uint idRoom, uint idTable, uint result)``` - записать результат игрока.
9. ```deleteRoomWithRates(uint idRoom)``` - удалить комнату со ставками.
10. ```setAwards(address newAwards)``` - изменить награды.
11. ```closeRoomWithoutBetsForcefully()``` - принудительно закрыть комнату без ставок.
12. ```withdrawalFunds(uint sum)``` - вывести средства с контракта.

### События:
1. При добавлении администратора ```AddAdmin(address)```.
2. При создании комнаты со ставками ```CreateRoomWithRates(uint id, uint betAmount, uint maxPlayers)```.
3. При создании комнаты без ставок ```CreateRoomWithoutBets(uint betAmount, uint roomLifeTime)```.
4. При добавлении игрока за стол ```PutPlayerTable(address player, uint idRoom, uint idTable)```.
5. При закрытии стола(окончание игры) ```PayRewards(address player, uint value, uint place, uint idRoom, uint idTable)```.
6. При удалении комнаты ```DeleteRoomWithRates(uint idRoom)```.
7. При установке комиссии ```SetFee(uint oldFee, uint newFee)```.
8. При установке наград ```SetAwards(address oldAwards, address newAwards)```.
9. При принудительном закрытии комнаты со ставками ```CloseRoomWithoutBetsForcefully(uint idRoom)```.
10. При выводе средств из контракта ```WithdrawalFunds(address admin, uint sum)```.
11. При установке адреса сервера ```ChangeServerAddr(address oldAddress, address newAddress)```.

### Комната без ставок
1. Создать комнату - ```createRoomWithoutBets(uint roomLifeTime) payable``` (передать средства).
2. Посадить игрока за стол - ```putPlayerTable(uint idRoom) payable``` (idRoom == 0).
3. Записать результат игрока - ```setResultPlayer(address player, uint idRoom, uint idTable, uint result)``` (idRoom == 0, idTable == 0).
4. Принудительно закрыть стол - ```closeRoomWithoutBetsForcefully()```.
