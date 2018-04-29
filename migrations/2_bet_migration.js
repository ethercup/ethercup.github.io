var Bet = artifacts.require("./Bet.sol");

module.exports = function(deployer) {
  deployer.deploy(Bet,
  	"Germany",
  	"Russia",
  	true,
  	1524515280,
  	100000,
  	3600*24,
  	{from: '0xd78d516f932daa9d40ac0ba2fd26c82942d11f1a', value:1000000000000});
};