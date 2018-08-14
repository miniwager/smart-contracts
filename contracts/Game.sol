pragma solidity ^0.4.11;


import "./interfaces/IAwards.sol";
import "./Admins.sol";


contract Game is Admins {

	struct Room {
	uint countIdTable;
	uint betAmount;
	uint maxPlayers;
	uint lastBusyTable;
	}

	struct RoomWithoutBets {
	uint betAmount;
	uint roomLifeTime;
	uint roomClosingTime;
	}

	struct Table {
	address[] players;
	uint[] results;
	bool[] status;
	uint countResults;
	}
	///////////////////////////////////////////////// Storage (begin)
	uint countIdRoom = 1;

	uint public fee;

	uint accumulatedFunds;

	IAwards awardsObj;

	RoomWithoutBets public roomWithoutBets;

	mapping (uint => Room) public rooms;

	mapping (uint => uint[]) public indexTables;

	mapping (uint => mapping (uint => Table)) public tables;

	mapping (address => bool) public playerPlays;

	mapping (uint => mapping (uint => mapping (address => uint))) playerIndex;
	///////////////////////////////////////////////// Storage (end)
	///////////////////////////////////////////////// Constructor (begin)
	function Game(uint _fee, address awardsAddress, address servAddress) public {
		require(_fee > 0 && awardsAddress != 0);

		fee = _fee;
		awardsObj = IAwards(awardsAddress);

		require(awardsObj.getAwards(2)[0] != 0);

		if (servAddress == 0)
		serverAddress = msg.sender;
		else
		serverAddress = servAddress;
	}
	///////////////////////////////////////////////// Constructor (end)
	///////////////////////////////////////////////// Set fee and awards (begin)
	event SetFee(uint oldFee, uint newFee);

	function setFee(uint _fee) public onlyAdmin {
		require(_fee > 0);
		SetFee(fee, _fee);
		fee = _fee;
	}

	event SetAwards(address oldAwards, address newAwards);

	function setAwards(address newAwards) public onlyAdmin {
		SetAwards(awardsObj, newAwards);
		awardsObj = IAwards(newAwards);
		require(awardsObj.getAwards(2)[0] != 0);
	}
	///////////////////////////////////////////////// Set fee and awards (end)
	///////////////////////////////////////////////// Checks (begin)
	function checkPlayerForTable(address player, address[] table) constant internal returns (bool){
		for (uint i = 0; i < table.length; i++) {
			if (table[i] == player) {
				return true;
			}
		}
		return false;
	}

	function checkAllPlayersFinishedPlaying(uint idRoom, uint idTable) constant internal returns (bool) {
		if ((idRoom != 0 && idTable != 0) && rooms[idRoom].maxPlayers > tables[idRoom][idTable].players.length)
		return false;

		if ((idRoom == 0 && idTable == 0) && roomWithoutBets.roomClosingTime > block.timestamp)
		return false;

		if (tables[idRoom][idTable].players.length != tables[idRoom][idTable].countResults)
		return false;

		return true;
	}
	///////////////////////////////////////////////// Checks (end)
	///////////////////////////////////////////////// Create room and table (begin)
	event CreateRoomWithRates(uint id, uint betAmount, uint maxPlayers);

	function createRoomWithRates(uint betAmount, uint maxPlayers) public onlyAdmin {
		require(betAmount != 0);
		require(maxPlayers > 1);

		rooms[countIdRoom] = Room(1, betAmount, maxPlayers, 0);
		CreateRoomWithRates(countIdRoom, betAmount, maxPlayers);
		countIdRoom++;
	}

	event CreateRoomWithoutBets(uint betAmount, uint roomLifeTime);

	function createRoomWithoutBets(uint roomLifeTime) public onlyAdmin payable {
		require(roomLifeTime > 0);
		require(roomWithoutBets.betAmount == 0);
		require(msg.value > 0);
		roomWithoutBets = RoomWithoutBets(msg.value, roomLifeTime, 0);
		CreateRoomWithoutBets(msg.value, roomLifeTime);
	}

	event PutPlayerTable(address player, uint idRoom, uint idTable);

	function putPlayerTable(uint idRoom) public payable {
		require(!playerPlays[msg.sender]);
		require(msg.value >= rooms[idRoom].betAmount);
		require(rooms[idRoom].countIdTable != 0);
		require(idRoom != 0);

		if (msg.value > rooms[idRoom].betAmount)
		require(msg.sender.send(msg.value - rooms[idRoom].betAmount));

		for (uint j = rooms[idRoom].lastBusyTable; j < indexTables[idRoom].length; j++) {
			if (!checkPlayerForTable(msg.sender, tables[idRoom][indexTables[idRoom][j]].players) &&
			tables[idRoom][indexTables[idRoom][j]].players.length < rooms[idRoom].maxPlayers) {
				tables[idRoom][indexTables[idRoom][j]].players.push(msg.sender);

				tables[idRoom][indexTables[idRoom][j]].results.push(0);
				tables[idRoom][indexTables[idRoom][j]].status.push(false);
				playerIndex[idRoom][indexTables[idRoom][j]][msg.sender] = tables[idRoom][indexTables[idRoom][j]].players.length - 1;

				if (tables[idRoom][indexTables[idRoom][j]].players.length == rooms[idRoom].maxPlayers)
				rooms[idRoom].lastBusyTable++;
				PutPlayerTable(msg.sender, idRoom, indexTables[idRoom][j]);
				playerPlays[msg.sender] = true;
				return;
			}
		}

		tables[idRoom][rooms[idRoom].countIdTable].players.push(msg.sender);

		tables[idRoom][rooms[idRoom].countIdTable].results.push(0);
		tables[idRoom][rooms[idRoom].countIdTable].status.push(false);
		playerIndex[idRoom][rooms[idRoom].countIdTable][msg.sender] = tables[idRoom][rooms[idRoom].countIdTable].players.length - 1;

		indexTables[idRoom].push(rooms[idRoom].countIdTable);
		PutPlayerTable(msg.sender, idRoom, rooms[idRoom].countIdTable);
		rooms[idRoom].countIdTable++;
		if (tables[idRoom][rooms[idRoom].countIdTable].players.length == rooms[idRoom].maxPlayers)
		rooms[idRoom].lastBusyTable++;
		playerPlays[msg.sender] = true;
	}

	function putPlayerTableRWB(address player) public onlyServer {
		require(!playerPlays[player]);
		require(roomWithoutBets.betAmount > 0);
		assert(!checkPlayerForTable(player, tables[0][0].players));

		if (roomWithoutBets.roomClosingTime == 0)
		roomWithoutBets.roomClosingTime = block.timestamp + roomWithoutBets.roomLifeTime;

		require(roomWithoutBets.roomClosingTime > block.timestamp);

		tables[0][0].players.push(player);

		tables[0][0].results.push(0);
		tables[0][0].status.push(false);
		playerIndex[0][0][player] = tables[0][0].players.length - 1;

		playerPlays[player] = true;
		PutPlayerTable(player, 0, 0);
	}
	///////////////////////////////////////////////// Create room and table (end)
	///////////////////////////////////////////////// Set result (begin)
	event SetResultPlayer(address player, uint idRoom, uint idTable, uint result);

	function setResultPlayer(address player, uint idRoom, uint idTable, uint result) public onlyServer {
		require(player != 0);
		assert(checkPlayerForTable(player, tables[idRoom][idTable].players));

		uint playerI = playerIndex[idRoom][idTable][player];

		require(tables[idRoom][idTable].status[playerI] != true);

		tables[idRoom][idTable].countResults++;

		tables[idRoom][idTable].results[playerI] = result;
		tables[idRoom][idTable].status[playerI] = true;
		SetResultPlayer(player, idRoom, idTable, result);
		playerPlays[player] = false;

		if (checkAllPlayersFinishedPlaying(idRoom, idTable)) {
			payRewards(idRoom, idTable);
			if (idRoom == 0 && idTable == 0) {
				deleteRoomWithoutBets();
			}
		}
	}
	///////////////////////////////////////////////// Set result (end)
	///////////////////////////////////////////////// Pay rewards (begin)
	event PayRewards(address player, uint value, uint place, uint idRoom, uint idTable);

	function payRewards(uint idRoom, uint idTable) constant internal {
		uint[] memory results = tables[idRoom][idTable].results;
		address[] memory addresses = tables[idRoom][idTable].players;

		uint i;
		uint key;
		address keyAddr;
		uint j;

		for (i = 1; i < results.length; i++) {
			key = results[i];
			keyAddr = addresses[i];

			for (j = i; j > 0 && results[j - 1] < key; j--) {
				results[j] = results[j - 1];
				addresses[j] = addresses[j - 1];
			}

			results[j] = key;
			addresses[j] = keyAddr;
		}

		transferRewards(results, addresses, idRoom, idTable);
	}

	function transferRewards(uint[] results, address[] addresses, uint idRoom, uint idTable) constant internal {
		uint bank;
		uint16[17] memory awards;
		if (idRoom != 0 && idTable != 0) {
			bank = (rooms[idRoom].maxPlayers * rooms[idRoom].betAmount) - ((rooms[idRoom].maxPlayers * rooms[idRoom].betAmount) * fee) / 10000;
			accumulatedFunds += ((rooms[idRoom].maxPlayers * rooms[idRoom].betAmount) * fee) / 10000;
			awards = awardsObj.getAwards(rooms[idRoom].maxPlayers);
		}
		else {
			bank = roomWithoutBets.betAmount;
			awards = awardsObj.getAwards(tables[0][0].players.length);
		}

		for (uint l = 0; l < awards.length && awards[l] != 0; l++) {
			if (l + 1 < addresses.length && results[l] == results[l + 1]) {
				uint count = 1;
				uint value = (bank * awards[l]) / 10000;
				for (uint t = l + 1; t < addresses.length; t++) {
					if (results[l] == results[t]) {
						if (t < awards.length && awards[t] != 0)
						value += (bank * awards[t]) / 10000;
						count++;
					}
					else {
						break;
					}
				}
				if (value / count > 0) {
					for (uint q = l; q < l + count; q++) {
						assert(addresses[q].send(value / count));
						PayRewards(addresses[q], value / count, q + 1, idRoom, idTable);
					}
				}
				else {
					accumulatedFunds += value;
				}
				l += count - 1;
			}
			else {
				assert(addresses[l].send((bank * awards[l]) / 10000));
				PayRewards(addresses[l], (bank * awards[l]) / 10000, l + 1, idRoom, idTable);
			}
		}
	}
	///////////////////////////////////////////////// Pay rewards (end)
	///////////////////////////////////////////////// Delete room (begin)
	event DeleteRoomWithRates(uint idRoom);

	function deleteRoomWithRates(uint idRoom) public onlyServer {
		require(rooms[idRoom].countIdTable != 0);

		for (uint j = 0; j < indexTables[idRoom].length; j++) {
			for (uint k = 0; k < tables[idRoom][indexTables[idRoom][j]].players.length; k++) {
				playerPlays[tables[idRoom][indexTables[idRoom][j]].players[k]] = false;

                if (!checkAllPlayersFinishedPlaying(idRoom, indexTables[idRoom][j])) {
                    require(tables[idRoom][indexTables[idRoom][j]].players[k].send(rooms[idRoom].betAmount));
                    PayRewards(tables[idRoom][indexTables[idRoom][j]].players[k], rooms[idRoom].betAmount, 1, idRoom, indexTables[idRoom][j]);
                }
			}
			delete tables[idRoom][indexTables[idRoom][j]].players;
			delete tables[idRoom][indexTables[idRoom][j]].status;
			delete tables[idRoom][indexTables[idRoom][j]].results;
			delete tables[idRoom][indexTables[idRoom][j]].countResults;
		}
		delete indexTables[idRoom];
        delete rooms[idRoom];
		DeleteRoomWithRates(idRoom);
	}

	event DeleteRoomWithoutBets(uint idRoom);

	function deleteRoomWithoutBets() internal {
		require(roomWithoutBets.betAmount > 0);

		delete roomWithoutBets;
		delete tables[0][0].players;
		delete tables[0][0].status;
		delete tables[0][0].results;
		delete tables[0][0].countResults;

		DeleteRoomWithoutBets(0);
	}
	///////////////////////////////////////////////// Delete room(end)
	///////////////////////////////////////////////// Withdrawal funds (begin)
	event WithdrawalFunds(address admin, uint sum);

	function withdrawalFunds(uint sum) public onlyAdmin {
		require(sum <= accumulatedFunds);

		if (sum == 0) {
			require(msg.sender.send(accumulatedFunds));
			WithdrawalFunds(msg.sender, accumulatedFunds);
			accumulatedFunds = 0;
		}
		else {
			require(msg.sender.send(sum));
			WithdrawalFunds(msg.sender, sum);
			accumulatedFunds -= sum;
		}
	}
	///////////////////////////////////////////////// Withdrawal funds (end)
	///////////////////////////////////////////////// Close RoomWithoutBets (begin)
	event CloseRoomWithoutBetsForcefully(uint idRoom);

	function closeRoomWithoutBetsForcefully() public onlyAdmin {
		require(roomWithoutBets.betAmount > 0);
		require(roomWithoutBets.roomClosingTime <= block.timestamp);
		assert(checkAllPlayersFinishedPlaying(0, 0));

		payRewards(0, 0);
		for (uint k = 0; k < tables[0][0].players.length; k++) {
			playerPlays[tables[0][0].players[k]] = false;
		}
		deleteRoomWithoutBets();
		CloseRoomWithoutBetsForcefully(0);
	}
	///////////////////////////////////////////////// Close RoomWithoutBets (end)
}
