const Awards = artifacts.require("./Awards.sol");
const Game = artifacts.require("./Game.sol");

module.exports = async (deployer, network, accounts) => {
	deployer.then(async () => {
		return Awards.new();
	}).then(AwardsInstance => {
		return Game.new(100, AwardsInstance.address, '0xda842fcd952ebc431097d57211d7bf3e5af6a913');
	}).catch(e => {
		console.log(e);
	});
};
