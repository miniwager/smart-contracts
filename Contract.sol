pragma solidity ^0.4.0;

contract StorageGame {
    
    struct GameInfoPlayer {
        bool setResult;
        uint result;
        uint reward;
    }
    
    struct Table {
        uint id;
        uint closingTime;
        
        uint bank;
        
        mapping(address => GameInfoPlayer) playersAndResult;
        address[] players;
    }
    
    struct RoomWithRates {
        uint id;
        uint countIdTable;
        uint betAmount;
        uint tableLifeTime;
        uint maxPlayers;
        uint numberPlayersOpenTable;
        
        uint fee;
        uint[] awardsPlace;
        
        uint tablesSize;
        Table[] tables;
    }
    
    struct PlayerLocation{
        uint idRoom;
        uint idTable;
    }


    
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



///////////////////////////////////////////////// Storage (begin)
    uint256 countIdRoomWithRates = 1;
    mapping(uint => RoomWithRates) public idAndRoomWR;
    uint[] roomWRId;
    uint public idAndRoomWRSize;
    
    mapping(address => PlayerLocation) public playerLocations;
    
    address[] addressesPlaceWinnings;
    GameInfoPlayer[] gameInfoPlayerPlaceWinnings;
///////////////////////////////////////////////// Storage (end)

    
    
    function StorageGame() {
        admins.push(msg.sender);
    }
    
    
    
///////////////////////////////////////////////// Create room and table (begin)
    event CreateRoomWithRates(uint id, uint betAmount, uint tableLifeTime, uint maxPlayers);
    // function createRoomWithRates(uint betAmount, uint tableLifeTime, uint maxPlayers) {
    function createRoomWithRates(uint betAmount, uint tableLifeTime, uint maxPlayers, uint[] awards) {
        if(isAdmin(msg.sender)){
            idAndRoomWR[countIdRoomWithRates].id = countIdRoomWithRates;
            idAndRoomWR[countIdRoomWithRates].countIdTable = 1;
            idAndRoomWR[countIdRoomWithRates].betAmount = betAmount;
            idAndRoomWR[countIdRoomWithRates].tableLifeTime = tableLifeTime;
            idAndRoomWR[countIdRoomWithRates].maxPlayers = maxPlayers;
            idAndRoomWR[countIdRoomWithRates].numberPlayersOpenTable = 0;
            
            for(uint i = 0; i < awards.length; i++){
                idAndRoomWR[countIdRoomWithRates].awardsPlace.push(awards[i]);
            }
            
            CreateRoomWithRates(countIdRoomWithRates, betAmount, tableLifeTime, maxPlayers);
            
            roomWRId.push(countIdRoomWithRates);
            idAndRoomWRSize++;
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



///////////////////////////////////////////////// Verification (begin)
    function checkValidTable(Table _table, uint _maxPlayers) internal returns (bool) {
        if(_table.closingTime < block.timestamp || _table.players.length >= _maxPlayers){
            return false;
        }
        return true;
    }
    
    function isNullRoomWithRates(RoomWithRates a) internal returns (bool) {
        if(a.id == 0){
            return true;
        }
        return false;
    }
    
    function playerPlays(address player) internal returns (bool) {
        PlayerLocation memory infoLoction = playerLocations[player];
        if(infoLoction.idRoom == 0 || infoLoction.idTable == 0){
            return false;
        }
        return true;
    }
///////////////////////////////////////////////// Verification (end)


///////////////////////////////////////////////// Start game (begin)
    event PutPlayerTable(address player, uint idRoom, uint idTable);
    function putPlayerTable(uint idRoom) payable {
        if(!isNullRoomWithRates(idAndRoomWR[idRoom]) && msg.value >= idAndRoomWR[idRoom].betAmount && !playerPlays(msg.sender)){
            
            uint value = msg.value - (msg.value/100) * idAndRoomWR[idRoom].fee;
            
            uint time = idAndRoomWR[idRoom].tableLifeTime + block.timestamp;
            if(idAndRoomWR[idRoom].tables.length == 0){
                idAndRoomWR[idRoom].tables.push(createTable(idAndRoomWR[idRoom].countIdTable, time));
                idAndRoomWR[idRoom].countIdTable++;
                idAndRoomWR[idRoom].tablesSize++;
            }
            
            uint offset = idAndRoomWR[idRoom].tables.length - 1;
            if(checkValidTable(idAndRoomWR[idRoom].tables[offset], idAndRoomWR[idRoom].maxPlayers)){
                idAndRoomWR[idRoom].tables[offset].playersAndResult[msg.sender] = GameInfoPlayer(false, 0, 0);
                idAndRoomWR[idRoom].tables[offset].players.push(msg.sender);
                
                idAndRoomWR[idRoom].tables[offset].bank += value;
        
                idAndRoomWR[idRoom].numberPlayersOpenTable++;
            } else {
                idAndRoomWR[idRoom].numberPlayersOpenTable = 0;
                idAndRoomWR[idRoom].tables.push(createTable(idAndRoomWR[idRoom].countIdTable, time));
                idAndRoomWR[idRoom].countIdTable++;
                idAndRoomWR[idRoom].tablesSize++;
                
                idAndRoomWR[idRoom].tables[offset + 1].playersAndResult[msg.sender] = GameInfoPlayer(false, 0, 0);
                idAndRoomWR[idRoom].tables[offset + 1].players.push(msg.sender);
                
                idAndRoomWR[idRoom].tables[offset + 1].bank += value;
                
                idAndRoomWR[idRoom].numberPlayersOpenTable++;
            }
            
            uint idroom = idAndRoomWR[idRoom].id;
            uint idtable = idAndRoomWR[idRoom].tables[idAndRoomWR[idRoom].tables.length - 1].id;
            playerLocations[msg.sender] = PlayerLocation(idroom, idtable);
            PutPlayerTable(msg.sender, idroom, idtable);
        }
    }
///////////////////////////////////////////////// Start game (end)
    
    
    
///////////////////////////////////////////////// Set result and pay rewards (begin)
    event SetResultPlayer(bool gameover, uint idRoom, uint idTable);
    function setResultPlayer(address player, uint result) {
        if(isAdmin(msg.sender) && playerPlays(player)){
            PlayerLocation memory infoLocation = playerLocations[player];
            
            bool set = idAndRoomWR[infoLocation.idRoom].tables[infoLocation.idTable - 1].playersAndResult[player].setResult;
            
            if(!set){
                idAndRoomWR[infoLocation.idRoom].tables[infoLocation.idTable - 1].playersAndResult[player].setResult = true;
                idAndRoomWR[infoLocation.idRoom].tables[infoLocation.idTable - 1].playersAndResult[player].result = result;
            }
            
            SetResultPlayer(false, infoLocation.idRoom, infoLocation.idTable);
            if(isGameOver(infoLocation.idRoom, infoLocation.idTable)){
                SetResultPlayer(true, infoLocation.idRoom, infoLocation.idTable);
                payRewards(infoLocation.idRoom, infoLocation.idTable);
            }
        }
    }
    
    function isGameOver(uint idRoom, uint idTable) internal returns(bool) {
        if(idAndRoomWR[idRoom].tables[idTable - 1].closingTime < block.timestamp){
            Table memory table = idAndRoomWR[idRoom].tables[idTable - 1];
            for(uint i = 0; i < table.players.length; i++){
                bool set = idAndRoomWR[idRoom].tables[idTable - 1].playersAndResult[table.players[i]].setResult;
                if(set == false){
                    return false;
                }
            }
        } else {
            return false;
        }
        return true;
    }
    
    event PayRewards(address player, uint value, uint place, uint idRoom, uint idTable);
    function payRewards(uint idRoom, uint idTable) internal {
        sortResultsTable(idRoom, idTable);
        PayRewards(addressesPlaceWinnings[i], value, i + 1, idRoom, idTable);
        for(uint i = 0; i < addressesPlaceWinnings.length; i++){
            uint value = idAndRoomWR[idRoom].tables[idTable - 1].playersAndResult[addressesPlaceWinnings[i]].reward;
            // addressesPlaceWinnings[i].transfer(value);
            PayRewards(addressesPlaceWinnings[i], value, i + 1, idRoom, idTable);
        }
    }
    
    function sortResultsTable(uint idRoom, uint idTable) internal {
        delete addressesPlaceWinnings;
        delete gameInfoPlayerPlaceWinnings;
        
        Table memory table = idAndRoomWR[idRoom].tables[idTable - 1];
        
        for(uint k = 0; k < table.players.length; k++){
            gameInfoPlayerPlaceWinnings.push(idAndRoomWR[idRoom].tables[idTable - 1].playersAndResult[table.players[k]]);
            addressesPlaceWinnings.push(table.players[k]);
        }
        
        GameInfoPlayer memory gameInfoTemp;
        address playerTemp;
        for(uint i = 0; i < table.players.length; i++){
            for(uint j = i + 1; j < table.players.length - (i + 1); j++){
                if(gameInfoPlayerPlaceWinnings[i].result < gameInfoPlayerPlaceWinnings[j].result){
                    gameInfoTemp = gameInfoPlayerPlaceWinnings[j];
                    playerTemp = addressesPlaceWinnings[j];
                    
                    gameInfoPlayerPlaceWinnings[j] = gameInfoPlayerPlaceWinnings[i];
                    addressesPlaceWinnings[j] = addressesPlaceWinnings[i];
                    
                    gameInfoPlayerPlaceWinnings[i] = gameInfoTemp;
                    addressesPlaceWinnings[i] = playerTemp;
                }
            }
        }
    }
    
    function calculateAwards(uint idRoom, uint idTable) internal {
        Table memory table = idAndRoomWR[idRoom].tables[idTable - 1];
        
        for(uint i = 0; i < idAndRoomWR[idRoom].awardsPlace.length; i++){
            if(i <= idAndRoomWR[idRoom].tables[idTable - 1].players.length){
                // idAndRoomWR[idRoom].tables[idTable - 1].players
            }
        }
    }
///////////////////////////////////////////////// Set result and pay rewards (end)
}


// function putPlayerTable(uint idRoom) payable{
    //     if(!isNullRoomWithRates(idAndRoomWR[idRoom]) && msg.value >= idAndRoomWR[idRoom].betAmount){
    //         RoomWithRates temp = idAndRoomWR[idRoom];
            
    //         if(temp.tables.length == 0){
    //             uint time = temp.tableLifeTime + block.timestamp;
    //             temp.tables.push(createTable(temp.countIdTable, time));
    //             temp.countIdTable++;
    //             temp.tablesSize++;
    //         }
            
    //         uint offset = temp.tables.length - 1;
    //         if(checkValidTable(temp.tables[offset], temp.maxPlayers)){
    //             temp.tables[offset].playersAndResult[msg.sender];
    //             temp.tables[offset].players.push(msg.sender);
    //             temp.tables[offset].playersAndResultSize++;
                
    //             temp.numberPlayersOpenTable++;
    //             idAndRoomWR[idRoom] = temp;
    //         } else {
    //             temp.numberPlayersOpenTable = 0;
    //             temp.tables.push(createTable(temp.countIdTable, temp.tableLifeTime + block.timestamp));
    //             temp.countIdTable++;
    //             temp.tablesSize++;
                
    //             temp.tables[offset + 1].playersAndResult[msg.sender];
    //             temp.tables[offset + 1].players.push(msg.sender);
    //             temp.tables[offset + 1].playersAndResultSize++;
                
    //             temp.numberPlayersOpenTable++;
    //             idAndRoomWR[idRoom] = temp;
    //         }
    //         playerLocations[msg.sender] = PlayerLocation(temp.id, temp.tables[temp.tables.length - 1].id);
    //         PutPlayerTable(msg.sender, temp.id, temp.tables[temp.tables.length - 1].id);
    //     }
    // }

