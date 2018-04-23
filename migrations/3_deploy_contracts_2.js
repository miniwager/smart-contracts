const Awards = artifacts.require("./Awards.sol");
const Game = artifacts.require("./Game.sol");

module.exports = async (deployer, network, accounts) => {
	let awardAddress = '0xe49499d5ed08dc3032803cde24c7f8fcc0a85bd3';

	if(network != 'live') {
		await Awards.new();
		awardAddress = Awards.address;
	}

	return Game.new(100, awardAddress, '0xdefb0902a0c59657e0739a429166283a016ccda6');
};
