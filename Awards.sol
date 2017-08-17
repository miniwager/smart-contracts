pragma solidity ^0.4.11;

contract Awards {
    
    mapping(uint => uint16[17]) public awards;
    
    function Awards() {
        awards[1]   = [10000]; //(100*100)
        awards[2]   = [5500,3500,1000];
        awards[3]   = [5000,3000,1500,500];
        awards[4]   = [4000,2400,1600,1000,600,400];
        awards[5]   = [3000,2000,1200,925,750,625,525,425,325,225];
        awards[6]   = [2750,1750,1150,850,725,575,450,300,200,150,120,100];
        awards[7]   = [2500,1650,1100,800,700,550,450,300,175,125,95,75,60];
        awards[8]   = [2500,1600,1050,800,700,550,450,300,175,125,95,75,50,40];
        awards[9]   = [2500,1500,1000,750,650,550,450,300,175,125,95,75,50,35,30];
        awards[10]  = [2500,1500,950,700,600,500,400,300,175,125,95,75,50,35,30,25];
        awards[11]  = [2500,1450,925,675,575,475,375,275,175,125,95,75,50,35,30,25,20];
    }
    
    function getAwards(uint maxPlayers) returns(uint16[17]) {
        assert(maxPlayers >= 2);
        
        if(maxPlayers == 2)
            return awards[1];
        
        uint index = maxPlayers / 10;
    
        if((index * 10) == maxPlayers)
            return awards[index + 1];
        if(index == 0)
            return awards[2];
            
        return index + 2 > 11 ? awards[11] : awards[index + 2];
    }
}
