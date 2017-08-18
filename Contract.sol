pragma solidity ^0.4.11;

contract Awards {
    mapping(uint8 => uint16[]) awards;
    function getAwards(uint maxPlayers) returns(uint16[17]);
}

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
        require(admins[msg.sender]);
        _;
    }
    
    modifier onlyServer {
        require(msg.sender == serverAddress);
        _;
    }
}

contract Game is admins {
    
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
    
    struct InformationsPlayer {
        bool status;
        uint result;
    }
///////////////////////////////////////////////// Storage (begin)
    uint countIdRoom = 1;
    uint public fee;
    uint accumulatedFunds;
    
    Awards awardsObj;
    
    RoomWithoutBets[] public roomWithoutBets;

    mapping(uint => Room) public rooms;
    
    mapping(uint => uint[]) public indexTables;
    mapping(uint => mapping(uint => address[])) public tables;
    
    mapping(address => bool) public playerPlays;
    
    mapping(uint => mapping(uint => mapping(address => InformationsPlayer))) public results;
///////////////////////////////////////////////// Storage (end)
///////////////////////////////////////////////// Constructor (begin)
    function Game(uint _fee, address awardsAddress, address servAddress) {
        assert(_fee > 0 && awardsAddress != 0);
        
        fee = _fee;
        awardsObj = Awards(awardsAddress);
        
        assert(awardsObj.getAwards(2)[0] != 0);
        
        if(servAddress == 0)
            serverAddress = msg.sender;
        else
            serverAddress = servAddress;
    }
///////////////////////////////////////////////// Constructor (end)
///////////////////////////////////////////////// Set fee and awards (begin)
    event SetFee(uint oldFee, uint newFee);
    function setFee(uint _fee) onlyAdmin {
        assert(_fee > 0);
        SetFee(fee, _fee);
        fee = _fee;
    }
    
    event SetAwards(address oldAwards, address newAwards);
    function setAwards(address newAwards) onlyAdmin {
        SetAwards(awardsObj, newAwards);
        awardsObj = Awards(newAwards);
        assert(awardsObj.getAwards(2)[0] != 0);
    }
///////////////////////////////////////////////// Set fee and awards (end)
///////////////////////////////////////////////// Checks (begin)
    function checkPlayerForTable(address player, address[] table) internal returns(bool){
        for(uint i = 0; i < table.length; i++){
            if(table[i] == player){
                return true;
            }
        }
        return false;
    }
    
    function checkAllPlayersFinishedPlaying(uint idRoom, uint idTable) internal returns (bool) {
        if((idRoom != 0 && idTable != 0) && rooms[idRoom].maxPlayers > tables[idRoom][idTable].length)
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
    function createRoomWithRates(uint betAmount, uint maxPlayers) onlyAdmin {
        assert(betAmount != 0);
        assert(maxPlayers > 1);
        
        rooms[countIdRoom] = Room(1, betAmount, maxPlayers, 0);
        CreateRoomWithRates(countIdRoom, betAmount, maxPlayers);
        countIdRoom++;
    }
    
    event CreateRoomWithoutBets(uint betAmount, uint roomLifeTime);
    function createRoomWithoutBets(uint roomLifeTime) onlyAdmin payable {
        assert(roomLifeTime != 0);
        assert(roomWithoutBets.length == 0);
        require(msg.value > 0);
        roomWithoutBets.push(RoomWithoutBets(msg.value, roomLifeTime, 0));
        CreateRoomWithoutBets(msg.value, roomLifeTime);
    }
    
    event PutPlayerTable(address player, uint idRoom, uint idTable);
    function putPlayerTable(uint idRoom) payable {
        require(!playerPlays[msg.sender]);
        
        if(idRoom == 0){
            assert(roomWithoutBets.length == 1);
            assert(msg.value == 0);
            assert(!checkPlayerForTable(msg.sender, tables[0][0]));
            
            if(roomWithoutBets[0].roomClosingTime == 0)
                roomWithoutBets[0].roomClosingTime = block.timestamp + roomWithoutBets[0].roomLifeTime;
            
            assert(roomWithoutBets[0].roomClosingTime > block.timestamp);
            
            tables[0][0].push(msg.sender);
            playerPlays[msg.sender] = true;
            PutPlayerTable(msg.sender, 0, 0);
            return;
        }
        
        require(msg.value >= rooms[idRoom].betAmount);
        require(rooms[idRoom].countIdTable != 0);
        require(idRoom != 0);

        if(msg.value > rooms[idRoom].betAmount)
            require(msg.sender.send(msg.value - rooms[idRoom].betAmount));
        
        for(uint j = rooms[idRoom].lastBusyTable; j < indexTables[idRoom].length; j++){
            if(!checkPlayerForTable(msg.sender, tables[idRoom][indexTables[idRoom][j]])){
                tables[idRoom][indexTables[idRoom][j]].push(msg.sender);
                if(tables[idRoom][indexTables[idRoom][j]].length == rooms[idRoom].maxPlayers)
                    rooms[idRoom].lastBusyTable++;
                PutPlayerTable(msg.sender, idRoom, indexTables[idRoom][j]);
                playerPlays[msg.sender] = true;
                return;
            }
        }
        
        tables[idRoom][rooms[idRoom].countIdTable].push(msg.sender);
        indexTables[idRoom].push(rooms[idRoom].countIdTable);
        PutPlayerTable(msg.sender, idRoom, rooms[idRoom].countIdTable);
        rooms[idRoom].countIdTable++;
        if(tables[idRoom][rooms[idRoom].countIdTable].length == rooms[idRoom].maxPlayers)
            rooms[idRoom].lastBusyTable++;
        playerPlays[msg.sender] = true;
    }
///////////////////////////////////////////////// Create room and table (end)
///////////////////////////////////////////////// Set result (begin)
    event SetResultPlayer(address player, uint idRoom, uint idTable, uint result);
    function setResultPlayer(address player, uint idRoom, uint idTable, uint result) onlyServer {
        assert(player != 0);
        assert(checkPlayerForTable(player, tables[idRoom][idTable]));
        assert(results[idRoom][idTable][player].status != true);

        results[idRoom][idTable][player].result = result;
        results[idRoom][idTable][player].status = true;
        SetResultPlayer(player, idRoom, idTable, result);
        playerPlays[player] = false;
        
        if(checkAllPlayersFinishedPlaying(idRoom, idTable)){
            if(idRoom != 0 && idTable != 0){
                payRewards(idRoom, idTable);
            }
            if(roomWithoutBets[0].roomClosingTime < block.timestamp){
                payRewards(idRoom, idTable);
                deleteRoomWithoutBets();
            }
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
        uint bank;
        uint16[17] memory awards;
        if(idRoom != 0 && idTable != 0){
            bank = (rooms[idRoom].maxPlayers * rooms[idRoom].betAmount) - ((rooms[idRoom].maxPlayers * rooms[idRoom].betAmount) * fee) / 10000;
            accumulatedFunds += ((rooms[idRoom].maxPlayers * rooms[idRoom].betAmount) * fee) / 10000;
            awards = awardsObj.getAwards(rooms[idRoom].maxPlayers);
        } else {
            bank = roomWithoutBets[0].betAmount;
            awards = awardsObj.getAwards(tables[0][0].length);
        }
        
        for(uint l = 0; awards[l] != 0; l++){
            require(addresses[l].send((bank * awards[l]) / 10000));
            PayRewards(addresses[l], (bank * awards[l]) / 10000, l+1, idRoom, idTable);
        }
    }
///////////////////////////////////////////////// Pay rewards (end)
///////////////////////////////////////////////// Delete room (begin)
    event DeleteRoomWithRates(uint idRoom);
    function deleteRoomWithRates(uint idRoom) onlyAdmin {
        assert(rooms[idRoom].countIdTable != 0);

        delete rooms[idRoom];
        for(uint j = 0; j < indexTables[idRoom].length; j++){
            for(uint k = 0; k < tables[idRoom][indexTables[idRoom][j]].length; k++){
                delete results[idRoom][indexTables[idRoom][j]][tables[idRoom][indexTables[idRoom][j]][k]];
                playerPlays[tables[idRoom][indexTables[idRoom][j]][k]] = false;
            }
            delete tables[idRoom][indexTables[idRoom][j]];
        }
        delete indexTables[idRoom];
        DeleteRoomWithRates(idRoom);
    }
    
    event DeleteRoomWithoutBets(uint idRoom);
    function deleteRoomWithoutBets() internal {
        assert(roomWithoutBets.length != 0);
        
        delete roomWithoutBets;
        for(uint i = 0; i < tables[0][0].length; i++){
            delete results[0][0][tables[0][0][i]];
        }
        delete tables[0][0];
        DeleteRoomWithoutBets(0);
    }
///////////////////////////////////////////////// Delete room(end)
///////////////////////////////////////////////// Withdrawal funds (begin)
    event WithdrawalFunds(address admin, uint sum);
    function withdrawalFunds(uint sum) onlyAdmin {
        require(sum <= accumulatedFunds);

        if(sum == 0){
            require(msg.sender.send(accumulatedFunds));
            WithdrawalFunds(msg.sender, accumulatedFunds);
            accumulatedFunds = 0;
        } else {
            require(msg.sender.send(sum));
            WithdrawalFunds(msg.sender, sum);
            accumulatedFunds -= sum;
        }
    }
///////////////////////////////////////////////// Withdrawal funds (end)
///////////////////////////////////////////////// Close RoomWithoutBets (begin)
    event CloseRoomWithoutBetsForcefully(uint idRoom);
    function closeRoomWithoutBetsForcefully() onlyAdmin {
        assert(roomWithoutBets.length > 0);
        
        payRewards(0, 0);
        for(uint k = 0; k < tables[0][0].length; k++){
            playerPlays[tables[0][0][k]] = false;
        }
        deleteRoomWithoutBets();
        CloseRoomWithoutBetsForcefully(0);
    }
///////////////////////////////////////////////// Close RoomWithoutBets (end)
}
