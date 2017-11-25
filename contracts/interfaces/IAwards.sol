pragma solidity ^0.4.11;


contract IAwards {
	mapping (uint8 => uint16[]) awards;

	function getAwards(uint maxPlayers) public view returns (uint16[17]);
}

