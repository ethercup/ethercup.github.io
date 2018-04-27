var Bet = artifacts.require("./Bet.sol");

module.exports = function(deployer) {
  deployer.deploy(Bet,
  	"Germany",
  	"Russia",
  	true,
  	1524515280,
  	100000);
};