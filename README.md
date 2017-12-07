### Contract deployment:
First of all, the contract with the awards is loaded.
When the contract is loaded, the constructor takes the commission, the address of the contract with the awards and the address of the server.
If the server address is not sent, the server will be ```sender```.

- [Awards abi](contracts/build/awards.abi.json)
- [Awards bytecode](contracts/build/awards.bytecode.bin)
- [Game abi](contracts/build/game.abi.json)
- [Game bytecode](contracts/build/game.bytecode.bin)

### Administration:
When creating a contract, the administrator becomes ```sender```.
Only the current administrator can add a new administrator.

### Get information from the contract::
1. If address is admin (```admins(address)```).
2. The address of the server (```serverAddress()```).
3. Room info (```rooms(public. key = idRoom (uint), value = {uint countIdTable, uint betAmount, uint maxPlayers, uint fee, uint[] awards, uint lastBusyTable})```).
4. Table info (```tables(uint idRoom, uint idTable) return(address[])```).
5. Gamer info (```results(uint idRoom, uint idTable, address player) return(InformationsPlayer{bool status, uint result})```).

### Methods:
1. ```addAdmin(address)``` - add admin.
2. ```changeServerAddr(address newAddress)``` - change server address.
3. ```setFee(uint _fee)``` - change fee.
4. ```setAwards(address newAwards)``` - change reward.
5. ```createRoomWithRates(uint betAmount, uint maxPlayers, uint[] awards)``` - create new room with bets.
6. ```createRoomWithoutBets(uint roomLifeTime) payable``` - create new room without bets.
7. ```putPlayerTable(uint idRoom) payable``` .
8. ```setResultPlayer(address player, uint idRoom, uint idTable, uint result)```.
9. ```deleteRoomWithRates(uint idRoom)```.
10. ```setAwards(address newAwards)```.
11. ```closeRoomWithoutBetsForcefully()```.
12. ```withdrawalFunds(uint sum)```.

### Events:
1. New admin - ```AddAdmin(address)```.
2. New room with bets - ```CreateRoomWithRates(uint id, uint betAmount, uint maxPlayers)```.
3. New room without bets - ```CreateRoomWithoutBets(uint betAmount, uint roomLifeTime)```.
4. New player on table - ```PutPlayerTable(address player, uint idRoom, uint idTable)```.
5. The end of the game - ```PayRewards(address player, uint value, uint place, uint idRoom, uint idTable)```.
6. When deleting the room - ```DeleteRoomWithRates(uint idRoom)```.
7. New fee - ```SetFee(uint oldFee, uint newFee)```.
8. New awards - ```SetAwards(address oldAwards, address newAwards)```.
9. When forcibly closing the room with the rates - ```CloseRoomWithoutBetsForcefully(uint idRoom)```.
10. When withdrawing funds from the contract - ```WithdrawalFunds(address admin, uint sum)```.
11. When setting the address of the server - ```ChangeServerAddr(address oldAddress, address newAddress)```.

### Room without bets
1. ```createRoomWithoutBets(uint roomLifeTime) payable``` (with funds).
2. ```putPlayerTable(uint idRoom) payable``` (idRoom == 0).
3. ```setResultPlayer(address player, uint idRoom, uint idTable, uint result)``` (idRoom == 0, idTable == 0).
4. ```closeRoomWithoutBetsForcefully()```.
