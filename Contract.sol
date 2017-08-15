pragma solidity ^0.4.8;
contract admins {
    
    mapping(address => bool) public admins;
    address public serverAddress;
    
    function admins() { admins[msg.sender] = true; }
    
    event AddAdmin(address newAdmin);
    function addAdmin(address a) onlyAdmin {
        admins[a] = true;
        AddAdmin(a);
    }
    
    event ChangeServerAddr(address oldAddress, address newAddress);
    function changeServerAddr(address newAddress) onlyAdmin {
        ChangeServerAddr(serverAddress, newAddress);
        serverAddress = newAddress;
    }
    
    modifier onlyAdmin {
        // require(admins[msg.sender]);
        if(!admins[msg.sender]) throw;
        _;
    }
    
    modifier onlyServer {
        // require(msg.sender == serverAddress);
        if(msg.sender != serverAddress) throw;
        _;
    }
}

contract Game is admins {
    
    struct Room {
        uint countIdTable;
        uint betAmount;
        uint maxPlayers;
        // uint fee;
        uint[] awards;
        uint lastBusyTable;
    }
    
    struct InformationsPlayer {
        // uint rate;
        bool status;
        uint result;
    }
///////////////////////////////////////////////// Storage (begin)
    uint countIdRoom = 1;
    
    uint public fee;
    
    uint[] public indexRooms;
    mapping(uint => Room) public rooms;
    
    mapping(uint => uint[]) public indexTables;
    mapping(uint => mapping(uint => address[])) public tables;
    
    mapping(uint => mapping(uint => mapping(address => InformationsPlayer))) public results;
///////////////////////////////////////////////// Storage (end)
///////////////////////////////////////////////// Constructor (begin)
    function Game(uint _fee, address servAddress) {
        fee = _fee;
        if(servAddress == 0)
            serverAddress = msg.sender;
        else
            serverAddress = servAddress;
    }
///////////////////////////////////////////////// Constructor (end)
///////////////////////////////////////////////// Set fee (begin)
    function setFee(uint _fee) onlyAdmin {
        // assert(_fee > 0);
        if(_fee == 0) throw;
        fee = _fee;
    }
///////////////////////////////////////////////// Set fee (end)
///////////////////////////////////////////////// Checks (begin)
    function checkPlayerForTable(address player, address[] table) internal returns(bool){
        for(uint i = 0; i < table.length; i++){
            if(table[i] == player){
                return true;
            }
        }
        return false;
    }
    
    function checkPlayerPlays(uint idRoom, address player) internal returns(bool){
        if(indexTables[idRoom].length == 0)
            return false;
        for(uint i = indexTables[idRoom].length; i > 0; i--){
            if(checkPlayerForTable(player, tables[idRoom][indexTables[idRoom][i - 1]])){
                if(results[idRoom][indexTables[idRoom][i - 1]][player].status == false){
                    return true;
                } else {
                    return false;
                }
            }
        }
        return false;
    }
    
    function checkAllPlayersFinishedPlaying(uint idRoom, uint idTable) internal returns (bool) {
        if(rooms[idRoom].maxPlayers > tables[idRoom][idTable].length)
            return false;
        for(uint i = 0; i < tables[idRoom][idTable].length; i++){
            if(results[idRoom][idTable][tables[idRoom][idTable][i]].status == false){
                return false;
            }
        }
        return true;
    }
///////////////////////////////////////////////// Checks (end)
///////////////////////////////////////////////// Create room and table (begin)
    event CreateRoomWithRates(uint id, uint betAmount, uint maxPlayers);
    function createRoomWithRates(uint betAmount, uint maxPlayers, uint[] awards) onlyAdmin {
        
        // assert(betAmount != 0);
        // assert(maxPlayers != 0);
        // assert(awards.length != 0);
        if(betAmount == 0 || maxPlayers == 0 || awards.length == 0) throw;
        
        rooms[countIdRoom].countIdTable = 1;
        rooms[countIdRoom].betAmount = betAmount;
        rooms[countIdRoom].maxPlayers = maxPlayers;
        // rooms[countIdRoom].fee = fee;
        rooms[countIdRoom].awards = awards;
        
        indexRooms.push(countIdRoom);
        
        CreateRoomWithRates(countIdRoom, betAmount, maxPlayers);
        countIdRoom++;
    }
    
    event PutPlayerTable(address player, uint idRoom, uint idTable);
    function putPlayerTableRoomWR(uint idRoom) payable {
        
        // require(msg.value >= rooms[idRoom].betAmount);
        // require(rooms[idRoom].countIdTable != 0);
        // require(!checkPlayerPlays(idRoom, msg.sender));
        // require(idRoom != 0);
        if(msg.value < rooms[idRoom].betAmount || rooms[idRoom].countIdTable == 0 || idRoom == 0 || checkPlayerPlays(idRoom, msg.sender)) throw;
        
        if(msg.value > rooms[idRoom].betAmount){
            if(!msg.sender.send(msg.value - rooms[idRoom].betAmount)) throw;
        }
        
        for(uint j = rooms[idRoom].lastBusyTable; j < indexTables[idRoom].length; j++){
            if(!checkPlayerForTable(msg.sender, tables[idRoom][indexTables[idRoom][j]])){
                tables[idRoom][indexTables[idRoom][j]].push(msg.sender);
                if(tables[idRoom][indexTables[idRoom][j]].length == rooms[idRoom].maxPlayers){
                    rooms[idRoom].lastBusyTable++;
                }
                PutPlayerTable(msg.sender, idRoom, indexTables[idRoom][j]);
                return;
            }
        }
        
        tables[idRoom][rooms[idRoom].countIdTable].push(msg.sender);
        indexTables[idRoom].push(rooms[idRoom].countIdTable);
        PutPlayerTable(msg.sender, idRoom, rooms[idRoom].countIdTable);
        rooms[idRoom].countIdTable++;
        if(tables[idRoom][rooms[idRoom].countIdTable].length == rooms[idRoom].maxPlayers){
            rooms[idRoom].lastBusyTable++;
        }
    }
///////////////////////////////////////////////// Create room and table (end)
///////////////////////////////////////////////// Set result (begin)
    event SetResultPlayer(address player, uint idRoom, uint idTable, uint result);
    function setResultPlayer(address player, uint idRoom, uint idTable, uint result) onlyServer {
        
        // assert(checkPlayerForTable(msg.sender, tables[idRoom][idTable]));
        // assert(results[idRoom][idTable][player].status != true);
        if(!checkPlayerForTable(player, tables[idRoom][idTable]) || results[idRoom][idTable][player].status == true) throw;

        results[idRoom][idTable][player].result = result;
        results[idRoom][idTable][player].status = true;
        SetResultPlayer(player, idRoom, idTable, result);
        
        if(checkAllPlayersFinishedPlaying(idRoom, idTable)){
            payRewards(idRoom, idTable);
        }
    }
///////////////////////////////////////////////// Set result (end)
///////////////////////////////////////////////// Pay rewards (begin)
    event PayRewards(address player, uint value, uint place, uint idRoom, uint idTable);
    function payRewards(uint idRoom, uint idTable) internal {
        address[] memory addresses = tables[idRoom][idTable];
        
        // Sorting results
        address tempAddress;
        for(uint j = 0; j < addresses.length; j++){
            for(uint k = j + 1; k < addresses.length - (j + 1); k++){
                if(results[idRoom][idTable][addresses[j]].result < results[idRoom][idTable][addresses[k]].result){
                    tempAddress = addresses[j];
                    addresses[j] = addresses[k];
                    addresses[k] = tempAddress;
                }
            }
        }
        
        transferRewards(addresses, idRoom, idTable);
    }
    
    function transferRewards(address[] addresses, uint idRoom, uint idTable) internal {
        uint bank = (rooms[idRoom].maxPlayers * rooms[idRoom].betAmount) - ((rooms[idRoom].maxPlayers * rooms[idRoom].betAmount) * fee) / 100;
        
        uint additionalReward = 0;
        for(uint l = 0; l < rooms[idRoom].awards.length; l++){
            if(l < addresses.length){
                // require(addresses[l].send((bank / 100) * rooms[idRoom].awards[l]));
                if(!addresses[l].send((bank / 100) * rooms[idRoom].awards[l])) throw;
                PayRewards(addresses[l], (bank / 100) * rooms[idRoom].awards[l], l+1, idRoom, idTable);
                continue;
            }
            additionalReward += (bank / 100) * rooms[idRoom].awards[l];
        }

        if(additionalReward / addresses.length > 0){
            for(uint t = 0; t < addresses.length; t++){
                // require(addresses[t].send(additionalReward / addresses.length));
                if(addresses[l].send(additionalReward / addresses.length)) throw;
                PayRewards(addresses[l], additionalReward / addresses.length, 0, idRoom, idTable);
            }
        }
    }
///////////////////////////////////////////////// Pay rewards (end)
///////////////////////////////////////////////// Delete (begin)
    function deleteRoom(uint idRoom) onlyAdmin {
        
        // assert(rooms[idRoom].countIdTable != 0);
        if(rooms[idRoom].countIdTable == 0) throw;
        
        delete rooms[idRoom];
        for(uint i = 0; i < indexRooms.length; i++){
            if(indexRooms[i] == idRoom){
                for (uint l = i; l < indexRooms.length - 1; l++){
                    indexRooms[l] = indexRooms[l + 1];
                }
                delete indexRooms[indexRooms.length - 1];
                indexRooms.length--;
                break;
            }
        }
        for(uint j = 0; j < indexTables[idRoom].length; j++){
            for(uint k = 0; k < tables[idRoom][indexTables[idRoom][j]].length; k++){
                delete results[idRoom][indexTables[idRoom][j]][tables[idRoom][indexTables[idRoom][j]][k]];
            }
            delete tables[idRoom][indexTables[idRoom][j]];
        }
        delete indexTables[idRoom];
    }
///////////////////////////////////////////////// Delete (end)
}
