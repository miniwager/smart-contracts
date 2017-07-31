pragma solidity ^0.4.8;

contract admins {
    
    address[] public admins;
    
    function admins() { admins.push(msg.sender); }

    modifier onlyAdmin {
        bool access = false;
        for(uint i = 0; i < admins.length; i++){
            if(admins[i] == msg.sender){
                access = true;
                break;
            }
        }
        if(!access) throw;
        _;
    }
}

contract Game is admins {
    
    struct GameInfoPlayer {
        bool setResult;
        uint result;
        uint reward;
        bool created;
    }
    
    struct Table {
        uint id;
        uint closingTime;
        uint bank;
    }
    
    struct RoomWithRates {
        uint id;
        uint countIdTable;
        uint betAmount;
        uint tableLifeTime;
        uint maxPlayers;
        uint numberPlayersOpenTable;
        uint fee;
    }
    
    struct PlayerLocation{
        uint idRoom;
        uint idTable;
    }

///////////////////////////////////////////////// Storage (begin)
    // Id room without bets
    uint public idRoomWithoutBets = 0;
    uint public bankRoomWithoutBets = 0;
    // Count rooms
    uint countIdRoom = 1;
    
    // Share awards
    mapping(uint => uint[]) public awardsPlace;
    
    // Player results
    mapping(uint => mapping(uint => address[])) public playersAndResultIndex;
    mapping(uint => mapping(uint => mapping(address => GameInfoPlayer))) public playersAndResult;
    
    // Tables
    mapping(uint => uint[]) public idRoomIdTableAndTableIndex;
    mapping(uint => mapping(uint => Table)) public idRoomIdTableAndTable;
    
    // Rooms
    uint[] idRoomAndRoomIndex;
    mapping(uint => RoomWithRates) public idRoomAndRoom;
    
    // Player location
    mapping(address => PlayerLocation) public playerLocations;
///////////////////////////////////////////////// Storage (end)

///////////////////////////////////////////////// Admin (begin)
    event AddAdmin(address newAdmin);
    function addAdmin(address a) onlyAdmin {
        admins.push(a);
        AddAdmin(a);
    }
    
    function withdrawalFunds(uint sum) onlyAdmin {
        uint value;
        if(sum == 0){
            value = this.balance;
        } else {
            value = sum;
        }
        if(!msg.sender.send(value)) throw;
    }
    
    function killGame(address addr) onlyAdmin {
        suicide(addr);
    }
///////////////////////////////////////////////// Admin (end)

///////////////////////////////////////////////// Create room and table (begin)
    event CreateRoomWithRates(uint id, uint betAmount, uint tableLifeTime, uint maxPlayers, uint fee);
    function createRoomWithRates(uint betAmount, uint tableLifeTime, uint maxPlayers, uint fee, uint[] awards) payable onlyAdmin {
            
        if(betAmount == 0 && maxPlayers == 0 && fee == 0 && (idRoomWithoutBets != 0 || msg.value == 0)){
            throw;
        } else if(betAmount == 0 && maxPlayers == 0 && fee == 0){
            idRoomWithoutBets = countIdRoom;
            bankRoomWithoutBets = msg.value;
        }
            
        idRoomAndRoom[countIdRoom].id = countIdRoom;
        idRoomAndRoom[countIdRoom].countIdTable = 1;
        idRoomAndRoom[countIdRoom].betAmount = betAmount;
        idRoomAndRoom[countIdRoom].tableLifeTime = tableLifeTime;
        idRoomAndRoom[countIdRoom].maxPlayers = maxPlayers;
        idRoomAndRoom[countIdRoom].numberPlayersOpenTable = 0;
        idRoomAndRoom[countIdRoom].fee = fee;
        idRoomAndRoomIndex.push(countIdRoom);
            
        for(uint i = 0; i < awards.length; i++){
            awardsPlace[countIdRoom].push(awards[i]);
        }
            
        CreateRoomWithRates(countIdRoom, betAmount, tableLifeTime, maxPlayers, fee);
        countIdRoom++;
    }
    
    function createTable(uint _id, uint _closingTime) internal returns (Table result) {
        result.id = _id;
        result.closingTime = _closingTime;
        result.bank = 0;
        return result;
    }
///////////////////////////////////////////////// Create room and table (end)

///////////////////////////////////////////////// Start game (begin)
    event PutPlayerTable(address player, uint idRoom, uint idTable);
    function putPlayerTable(uint idRoom) payable {
        if(idRoomAndRoom[idRoom].id != 0){
            if(isRoomWB(idRoom)){
                putPlayerTableRoomWB(idRoom);
            } else {
                putPlayerTableRoomWR(idRoom);
            }
        } else {
            throw;
        }
    }
    function putPlayerTableRoomWR(uint idRoom) internal {
        if(msg.value >= idRoomAndRoom[idRoom].betAmount && idRoomAndRoom[idRoom].maxPlayers > 0 &&
          (playerLocations[msg.sender].idRoom == 0 && playerLocations[msg.sender].idTable == 0)){
            
            uint value = msg.value - (msg.value/100) * idRoomAndRoom[idRoom].fee;
            uint closingTime1 = block.timestamp + idRoomAndRoom[idRoom].tableLifeTime;
            
            if(idRoomIdTableAndTableIndex[idRoom].length == 0){
                uint idTableTemp = idRoomAndRoom[idRoom].countIdTable;
                idRoomIdTableAndTable[idRoom][idTableTemp] = createTable(idTableTemp, closingTime1);
                idRoomIdTableAndTableIndex[idRoom].push(idTableTemp);
                idRoomAndRoom[idRoom].countIdTable++;
            }
            
            uint offset = idRoomIdTableAndTableIndex[idRoom].length;
            uint maxPlayers = idRoomAndRoom[idRoom].maxPlayers;
            uint tablePlayers = playersAndResultIndex[idRoom][offset].length;
            uint closingTime2 = idRoomIdTableAndTable[idRoom][offset].closingTime;
            
            if(closingTime2 > block.timestamp && tablePlayers < maxPlayers){
                idRoomIdTableAndTable[idRoom][offset].bank += value;
                playersAndResult[idRoom][offset][msg.sender].setResult = false;
                playersAndResult[idRoom][offset][msg.sender].result = 0;
                playersAndResult[idRoom][offset][msg.sender].reward = 0;
                playersAndResult[idRoom][offset][msg.sender].created = true;
                
                idRoomAndRoom[idRoom].numberPlayersOpenTable++;
                
                playersAndResultIndex[idRoom][offset].push(msg.sender);
            } else {
                uint idTableTemp2 = idRoomAndRoom[idRoom].countIdTable;
                idRoomIdTableAndTable[idRoom][idTableTemp2] = createTable(idTableTemp2, closingTime1);
                idRoomIdTableAndTableIndex[idRoom].push(idTableTemp2);
                idRoomAndRoom[idRoom].countIdTable++;
                idRoomAndRoom[idRoom].numberPlayersOpenTable = 1;
                
                idRoomIdTableAndTable[idRoom][idTableTemp2].bank += value;
                playersAndResult[idRoom][idTableTemp2][msg.sender].setResult = false;
                playersAndResult[idRoom][idTableTemp2][msg.sender].result = 0;
                playersAndResult[idRoom][idTableTemp2][msg.sender].reward = 0;
                playersAndResult[idRoom][idTableTemp2][msg.sender].created = true;
                
                playersAndResultIndex[idRoom][idTableTemp2].push(msg.sender);
            }
            
            uint idroom = idRoomAndRoom[idRoom].id;
            uint idtable = idRoomIdTableAndTableIndex[idRoom].length;
            playerLocations[msg.sender] = PlayerLocation(idroom, idtable);
            PutPlayerTable(msg.sender, idroom, idtable);
        } else {
            throw;
        }
    }
    
    function putPlayerTableRoomWB(uint idRoom) internal {
        if(playerLocations[msg.sender].idRoom == 0 && playerLocations[msg.sender].idTable == 0){
            
            uint closingTime1 = block.timestamp + idRoomAndRoom[idRoom].tableLifeTime;
            
            if(idRoomIdTableAndTableIndex[idRoom].length == 0){
                uint idTableTemp = idRoomAndRoom[idRoom].countIdTable;
                idRoomIdTableAndTable[idRoom][idTableTemp] = createTable(idTableTemp, closingTime1);
                idRoomIdTableAndTableIndex[idRoom].push(idTableTemp);
                idRoomIdTableAndTable[idRoom][idTableTemp].bank = bankRoomWithoutBets;
                idRoomAndRoom[idRoom].countIdTable++;
            }
            
            uint offset = idRoomIdTableAndTableIndex[idRoom].length;
            uint closingTime2 = idRoomIdTableAndTable[idRoom][offset].closingTime;
            
            if(closingTime2 > block.timestamp){
                playersAndResult[idRoom][offset][msg.sender].setResult = false;
                playersAndResult[idRoom][offset][msg.sender].result = 0;
                playersAndResult[idRoom][offset][msg.sender].reward = 0;
                playersAndResult[idRoom][offset][msg.sender].created = true;
                idRoomAndRoom[idRoom].numberPlayersOpenTable++;
                playersAndResultIndex[idRoom][offset].push(msg.sender);
            }
            
            uint idroom = idRoomAndRoom[idRoom].id;
            uint idtable = idRoomIdTableAndTableIndex[idRoom].length;
            playerLocations[msg.sender] = PlayerLocation(idroom, idtable);
            PutPlayerTable(msg.sender, idroom, idtable);
        } else {
            throw;
        }
    }
///////////////////////////////////////////////// Start game (end)

///////////////////////////////////////////////// Verification (begin)
    function isGameOver(uint idRoom, uint idTable) internal returns(bool) {
        if(idRoomIdTableAndTable[idRoom][idTable].closingTime < block.timestamp){
            uint length = playersAndResultIndex[idRoom][idTable].length;
            for(uint i = 0; i < length; i++){
                bool set = playersAndResult[idRoom][idTable][playersAndResultIndex[idRoom][idTable][i]].setResult;
                if(set == false){
                    return false;
                }
            }
        } else {
            return false;
        }
        return true;
    }
    
    function isRoomWB(uint idRoom) internal returns (bool) {
        if(idRoomAndRoom[idRoom].betAmount == 0 && idRoomAndRoom[idRoom].maxPlayers == 0 && idRoomAndRoom[idRoom].fee == 0){
            return true;
        }
        return false;
    }
///////////////////////////////////////////////// Verification (end)

///////////////////////////////////////////////// Set result and pay rewards (begin)
    event SetResultPlayer(uint idRoom, uint idTable);
    function setResultPlayer(address player, uint result) onlyAdmin {
        if(playerLocations[player].idRoom != 0 && playerLocations[player].idTable != 0){
            
            PlayerLocation memory infoLocation = playerLocations[player];
            bool set = playersAndResult[infoLocation.idRoom][infoLocation.idTable][player].setResult;
            if(!set){
                playersAndResult[infoLocation.idRoom][infoLocation.idTable][player].setResult = true;
                playersAndResult[infoLocation.idRoom][infoLocation.idTable][player].result = result;
            }
            if(isGameOver(infoLocation.idRoom, infoLocation.idTable)){
                SetResultPlayer(infoLocation.idRoom, infoLocation.idTable);
                payRewards(infoLocation.idRoom, infoLocation.idTable);
            }
        } else {
            throw;
        }
    }
    
    event PayRewards(address player, uint value, uint place, uint idRoom, uint idTable);
    function payRewards(uint idRoom, uint idTable) internal {
        address[] memory addresses = playersAndResultIndex[idRoom][idTable];
        
        // Sorting results
        address tempAddress;
        for(uint j = 0; j < addresses.length; j++){
            for(uint k = j + 1; k < addresses.length - (j + 1); k++){
                if(playersAndResult[idRoom][idTable][addresses[j]].result < playersAndResult[idRoom][idTable][addresses[k]].result){
                    tempAddress = addresses[j];
                    addresses[j] = addresses[k];
                    addresses[k] = tempAddress;
                }
            }
        }
        
        transferRewards(addresses, idRoom, idTable);
        
        if(isRoomWB(idRoom)){
            deleteRoom(idRoom);
        } else {
            deleteInfoTable(idRoom, idTable);
        }
    }
    
    function transferRewards(address[] addresses, uint idRoom, uint idTable) internal {
        uint additionalReward = 0;
        for(uint l = 0; l < awardsPlace[idRoom].length; l++){
            if(l < addresses.length){
                uint reward = (idRoomIdTableAndTable[idRoom][idTable].bank / 100) * awardsPlace[idRoom][l];
                if(!addresses[l].send(reward))
                    throw;
                continue;
            }
            additionalReward += (idRoomIdTableAndTable[idRoom][idTable].bank / 100) * awardsPlace[idRoom][l];
        }
        uint additionalRewardTransfer = additionalReward / addresses.length;
        if(additionalRewardTransfer > 0){
            for(uint t = 0; t < addresses.length; t++){
                if(!addresses[t].send(additionalRewardTransfer))
                    throw;
            }
        }
    }
///////////////////////////////////////////////// Set result and pay rewards (end)

///////////////////////////////////////////////// Delete table and root (begin)
    function deleteInfoTable(uint idRoom, uint idTable) internal {
        address[] memory addresses = playersAndResultIndex[idRoom][idTable];
        for(uint i = 0; i < addresses.length; i++){
            delete playersAndResult[idRoom][idTable][addresses[i]];
            delete playerLocations[addresses[i]];
        }
        delete playersAndResultIndex[idRoom][idTable];
    }
    event DeleteRoom(uint idRoom);
    function deleteRoom(uint idRoom) onlyAdmin {
            
        if(isRoomWB(idRoom)){
            idRoomWithoutBets = 0;
            bankRoomWithoutBets = 0;
        }
            
        delete awardsPlace[idRoom];
            
        uint[] memory tableIndex = idRoomIdTableAndTableIndex[idRoom];
        for(uint i = 0; i < tableIndex.length; i++){
            deleteInfoTable(idRoom, tableIndex[i]);
            delete idRoomIdTableAndTable[idRoom][tableIndex[i]];
        }
        delete idRoomIdTableAndTableIndex[idRoom];
            
        for(uint j = 0; j < idRoomAndRoomIndex.length; j++){
            if(idRoomAndRoomIndex[j] == idRoom){
                delete idRoomAndRoomIndex[j];
            }
        }
        delete idRoomAndRoom[idRoom];
        DeleteRoom(idRoom);
    }
///////////////////////////////////////////////// Delete table and root (end)
    function () payable {}
}

