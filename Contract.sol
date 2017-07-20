pragma solidity ^0.4.0;

contract StorageGame {
    
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
    uint countIdRoomWithRates = 1;
    
    // Share awards
    mapping(uint => uint[]) public awardsPlace;
    
    // Player results
    mapping(uint => mapping(uint => address[])) public playersAndResultIndex;
    mapping(uint => mapping(uint => mapping(address => GameInfoPlayer))) public playersAndResult;
    
    // Tables
    mapping(uint => uint[]) public idRoomIdTableAndTableIndex;
    mapping(uint => mapping(uint => Table)) public idRoomIdTableAndTable;
    
    // Rooms
    uint[] idRoomAndRoomWRIndex;
    mapping(uint => RoomWithRates) public idRoomAndRoomWR;
    
    // Player location
    mapping(address => PlayerLocation) public playerLocations;
///////////////////////////////////////////////// Storage (end)


    
///////////////////////////////////////////////// Admin (begin)
    address[] public admins;
    
    event AddAdmin(address newAdmin);
    function addAdmin(address a) {
        if(isAdmin(msg.sender)){
            admins.push(a);
            AddAdmin(a);
        }
    }
    
    function isAdmin(address a) internal returns (bool) {
        bool access = false;
        for(uint i = 0; i < admins.length; i++){
            if(admins[i] == a){
                access = true;
                break;
            }
        }
        return access;
    }
///////////////////////////////////////////////// Admin (end)
    
    
    
    function StorageGame() {
        admins.push(msg.sender);
    }
    
    function () payable {}
    
    
///////////////////////////////////////////////// Create room and table (begin)
    event CreateRoomWithRates(uint id, uint betAmount, uint tableLifeTime, uint maxPlayers, uint fee);
    function createRoomWithRates(uint betAmount, uint tableLifeTime, uint maxPlayers, uint fee, uint[] awards) payable {
        if(isAdmin(msg.sender)){
            
            if(betAmount == 0 && maxPlayers == 0 && fee == 0 && (idRoomWithoutBets != 0 || msg.value == 0)){
                CreateRoomWithRates(0, 0, 0, 0, 0);
                return;
            } else if(betAmount == 0 && maxPlayers == 0 && fee == 0){
                idRoomWithoutBets = countIdRoomWithRates;
                bankRoomWithoutBets = msg.value;
            }
            
            idRoomAndRoomWR[countIdRoomWithRates].id = countIdRoomWithRates;
            idRoomAndRoomWR[countIdRoomWithRates].countIdTable = 1;
            idRoomAndRoomWR[countIdRoomWithRates].betAmount = betAmount;
            idRoomAndRoomWR[countIdRoomWithRates].tableLifeTime = tableLifeTime;
            idRoomAndRoomWR[countIdRoomWithRates].maxPlayers = maxPlayers;
            idRoomAndRoomWR[countIdRoomWithRates].numberPlayersOpenTable = 0;
            idRoomAndRoomWR[countIdRoomWithRates].fee = fee;
            idRoomAndRoomWRIndex.push(countIdRoomWithRates);
            
            for(uint i = 0; i < awards.length; i++){
                awardsPlace[countIdRoomWithRates].push(awards[i]);
            }
            
            CreateRoomWithRates(countIdRoomWithRates, betAmount, tableLifeTime, maxPlayers, fee);
            countIdRoomWithRates++;
        }
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
        if(idRoomAndRoomWR[idRoom].id != 0){
            if(isRoomWB(idRoom)){
                putPlayerTableRoomWB(idRoom);
            } else {
                putPlayerTableRoomWR(idRoom);
            }
        }
    }

    function putPlayerTableRoomWR(uint idRoom) internal {
        if(msg.value >= idRoomAndRoomWR[idRoom].betAmount && idRoomAndRoomWR[idRoom].maxPlayers > 0 &&
          (playerLocations[msg.sender].idRoom == 0 && playerLocations[msg.sender].idTable == 0)){
            
            uint value = msg.value - (msg.value/100) * idRoomAndRoomWR[idRoom].fee;
            uint closingTime1 = block.timestamp + idRoomAndRoomWR[idRoom].tableLifeTime;
            
            if(idRoomIdTableAndTableIndex[idRoom].length == 0){
                uint idTableTemp = idRoomAndRoomWR[idRoom].countIdTable;
                idRoomIdTableAndTable[idRoom][idTableTemp] = createTable(idTableTemp, closingTime1);
                idRoomIdTableAndTableIndex[idRoom].push(idTableTemp);
                idRoomAndRoomWR[idRoom].countIdTable++;
            }
            
            uint offset = idRoomIdTableAndTableIndex[idRoom].length;
            uint maxPlayers = idRoomAndRoomWR[idRoom].maxPlayers;
            uint tablePlayers = playersAndResultIndex[idRoom][offset].length;
            uint closingTime2 = idRoomIdTableAndTable[idRoom][offset].closingTime;
            
            if(closingTime2 > block.timestamp && tablePlayers < maxPlayers){
                idRoomIdTableAndTable[idRoom][offset].bank += value;
                playersAndResult[idRoom][offset][msg.sender].setResult = false;
                playersAndResult[idRoom][offset][msg.sender].result = 0;
                playersAndResult[idRoom][offset][msg.sender].reward = 0;
                playersAndResult[idRoom][offset][msg.sender].created = true;
                
                idRoomAndRoomWR[idRoom].numberPlayersOpenTable++;
                
                playersAndResultIndex[idRoom][offset].push(msg.sender);
            } else {
                uint idTableTemp2 = idRoomAndRoomWR[idRoom].countIdTable;
                idRoomIdTableAndTable[idRoom][idTableTemp2] = createTable(idTableTemp2, closingTime1);
                idRoomIdTableAndTableIndex[idRoom].push(idTableTemp2);
                idRoomAndRoomWR[idRoom].countIdTable++;
                idRoomAndRoomWR[idRoom].numberPlayersOpenTable++;
                
                idRoomIdTableAndTable[idRoom][idTableTemp2].bank += value;
                playersAndResult[idRoom][idTableTemp2][msg.sender].setResult = false;
                playersAndResult[idRoom][idTableTemp2][msg.sender].result = 0;
                playersAndResult[idRoom][idTableTemp2][msg.sender].reward = 0;
                playersAndResult[idRoom][idTableTemp2][msg.sender].created = true;
                
                playersAndResultIndex[idRoom][idTableTemp2].push(msg.sender);
            }
            
            uint idroom = idRoomAndRoomWR[idRoom].id;
            uint idtable = idRoomIdTableAndTableIndex[idRoom].length;
            playerLocations[msg.sender] = PlayerLocation(idroom, idtable);
            PutPlayerTable(msg.sender, idroom, idtable);
        }
    }
    
    function putPlayerTableRoomWB(uint idRoom) internal {
        if(playerLocations[msg.sender].idRoom == 0 && playerLocations[msg.sender].idTable == 0){
            
            uint closingTime1 = block.timestamp + idRoomAndRoomWR[idRoom].tableLifeTime;
            
            if(idRoomIdTableAndTableIndex[idRoom].length == 0){
                uint idTableTemp = idRoomAndRoomWR[idRoom].countIdTable;
                idRoomIdTableAndTable[idRoom][idTableTemp] = createTable(idTableTemp, closingTime1);
                idRoomIdTableAndTableIndex[idRoom].push(idTableTemp);
                idRoomIdTableAndTable[idRoom][idTableTemp].bank = bankRoomWithoutBets;
                idRoomAndRoomWR[idRoom].countIdTable++;
            }
            
            uint offset = idRoomIdTableAndTableIndex[idRoom].length;
            uint closingTime2 = idRoomIdTableAndTable[idRoom][offset].closingTime;
            
            if(closingTime2 > block.timestamp){
                playersAndResult[idRoom][offset][msg.sender].setResult = false;
                playersAndResult[idRoom][offset][msg.sender].result = 0;
                playersAndResult[idRoom][offset][msg.sender].reward = 0;
                playersAndResult[idRoom][offset][msg.sender].created = true;
                idRoomAndRoomWR[idRoom].numberPlayersOpenTable++;
                playersAndResultIndex[idRoom][offset].push(msg.sender);
            }
            
            uint idroom = idRoomAndRoomWR[idRoom].id;
            uint idtable = idRoomIdTableAndTableIndex[idRoom].length;
            playerLocations[msg.sender] = PlayerLocation(idroom, idtable);
            PutPlayerTable(msg.sender, idroom, idtable);
        }
    }
///////////////////////////////////////////////// Start game (end)



///////////////////////////////////////////////// Set result and pay rewards (begin)
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
        if(idRoomAndRoomWR[idRoom].betAmount == 0 && idRoomAndRoomWR[idRoom].maxPlayers == 0 && idRoomAndRoomWR[idRoom].fee == 0){
            return true;
        }
        return false;
    }

    event SetResultPlayer(uint idRoom, uint idTable);
    function setResultPlayer(address player, uint result) {
        if(isAdmin(msg.sender) && playerLocations[msg.sender].idRoom != 0 &&
           playerLocations[msg.sender].idTable != 0){
            
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
        }
    }
    
    event PayRewards(address player, uint value, uint place, uint idRoom, uint idTable);
    function payRewards(uint idRoom, uint idTable) internal {

        uint length = playersAndResultIndex[idRoom][idTable].length;
        uint reward = idRoomIdTableAndTable[idRoom][idTable].bank / length;
    
        if(reward > 0){
            for(uint i = 0; i < length; i++){
                address addr = playersAndResultIndex[idRoom][idTable][i];
                if(!addr.send(reward))
                    throw;
                PayRewards(playersAndResultIndex[idRoom][idTable][i], reward, i + 1, idRoom, idTable);
            }
        }
        
        if(isRoomWB(idRoom)){
            deleteRoom(idRoom);
        } else {
            deleteInfoTable(idRoom, idTable);
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
    function deleteRoom(uint idRoom) {
        if(isAdmin(msg.sender)){
            
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
            
            for(uint j = 0; j < idRoomAndRoomWRIndex.length; j++){
                if(idRoomAndRoomWRIndex[j] == idRoom){
                    delete idRoomAndRoomWRIndex[j];
                }
            }
            delete idRoomAndRoomWR[idRoom];
            DeleteRoom(idRoom);
        }
    }
///////////////////////////////////////////////// Delete table and root (end)



///////////////////////////////////////////////// Verification (begin)
    // function checkValidTable(Table _table, uint _maxPlayers) internal returns (bool) {
    //     if(_table.closingTime < block.timestamp || _table.players.length >= _maxPlayers){
    //         return false;
    //     }
    //     return true;
    // }
    
//     function isNullRoomWithRates(RoomWithRates a) internal returns (bool) {
//         if(a.id == 0){
//             return true;
//         }
//         return false;
//     }
    
//     function playerPlays(address player) internal returns (bool) {
//         PlayerLocation memory infoLoction = playerLocations[player];
//         if(infoLoction.idRoom == 0 || infoLoction.idTable == 0){
//             return false;
//         }
//         return true;
//     }
    
//     function isGameOver(uint idRoom, uint idTable) internal returns(bool) {
//         if(idAndRoomWR[idRoom].tables[idTable - 1].closingTime < block.timestamp){
//             Table memory table = idAndRoomWR[idRoom].tables[idTable - 1];
//             for(uint i = 0; i < table.players.length; i++){
//                 bool set = idAndRoomWR[idRoom].tables[idTable - 1].playersAndResult[table.players[i]].setResult;
//                 if(set == false){
//                     return false;
//                 }
//             }
//         } else {
//             return false;
//         }
//         return true;
//     }
// ///////////////////////////////////////////////// Verification (end)



// ///////////////////////////////////////////////// Preparation of results (begin)
//     function preparationResults(uint idRoom, uint idTable) internal {
//         sortResultsTable(idRoom, idTable);
//         calculateAwards(idRoom, idTable);
//     }

//     function sortResultsTable(uint idRoom, uint idTable) internal {
//         delete addressesPlaceWinnings;
//         delete gameInfoPlayerPlaceWinnings;
        
//         Table memory table = idAndRoomWR[idRoom].tables[idTable - 1];
        
//         for(uint k = 0; k < table.players.length; k++){
//             gameInfoPlayerPlaceWinnings.push(idAndRoomWR[idRoom].tables[idTable - 1].playersAndResult[table.players[k]]);
//             addressesPlaceWinnings.push(table.players[k]);
//         }
        
//         GameInfoPlayer memory gameInfoTemp;
//         address playerTemp;
//         for(uint i = 0; i < table.players.length; i++){
//             for(uint j = i + 1; j < table.players.length - (i + 1); j++){
//                 if(gameInfoPlayerPlaceWinnings[i].result < gameInfoPlayerPlaceWinnings[j].result){
//                     gameInfoTemp = gameInfoPlayerPlaceWinnings[j];
//                     playerTemp = addressesPlaceWinnings[j];
                    
//                     gameInfoPlayerPlaceWinnings[j] = gameInfoPlayerPlaceWinnings[i];
//                     addressesPlaceWinnings[j] = addressesPlaceWinnings[i];
                    
//                     gameInfoPlayerPlaceWinnings[i] = gameInfoTemp;
//                     addressesPlaceWinnings[i] = playerTemp;
//                 }
//             }
//         }
//     }
    
//     function calculateAwards(uint idRoom, uint idTable) internal {
//         for(uint i = 0; i < idAndRoomWR[idRoom].awardsPlace.length; i++){
//             uint summ = 0;
//             if(i <= addressesPlaceWinnings.length){
//                 uint value = (idAndRoomWR[idRoom].tables[idTable - 1].bank / 100) * idAndRoomWR[idRoom].awardsPlace[i];
//                 address addrTemp = addressesPlaceWinnings[i];
//                 idAndRoomWR[idRoom].tables[idTable - 1].playersAndResult[addrTemp].reward = value;
//             } else {
//                 summ += (idAndRoomWR[idRoom].tables[idTable - 1].bank / 100) * idAndRoomWR[idRoom].awardsPlace[i];
//             }
            
//             uint additive = summ / idAndRoomWR[idRoom].tables[idTable - 1].players.length;
            
//             for(uint j = 0; j < addressesPlaceWinnings.length; j++){
//                 address addr = addressesPlaceWinnings[j];
//                 idAndRoomWR[idRoom].tables[idTable - 1].playersAndResult[addr].reward += additive;
//             }
//         }
//     }
// ///////////////////////////////////////////////// Preparation of results (end)
}



