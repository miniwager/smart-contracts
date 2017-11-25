pragma solidity ^0.4.11;


contract Admins {

	mapping (address => bool) public admins;

	address public serverAddress;

	function Admins() public {admins[msg.sender] = true;}

	event AddAdmin(address newAdmin);
	event RemoveAdmin(address adminAdress);

	function removeAdmin(address a) public onlyAdmin {
		admins[a] = false;
		RemoveAdmin(a);
	}

	function addAdmin(address a) public onlyAdmin {
		admins[a] = true;
		AddAdmin(a);
	}

	event ChangeServerAddr(address oldAddress, address newAddress);

	function changeServerAddr(address newAddress) public onlyAdmin {
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