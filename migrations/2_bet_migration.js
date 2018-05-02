var Bet = artifacts.require("./Bet.sol");

module.exports = function(deployer) {
  deployer.deploy(Bet,
  	'Germany',
  	'Russia',
  	true,
  	1524515280,
  	100000,
  	3600*24,
  	{from: '0x680f01bdf21ca9c54a096e9e471ca7749a4d1588', value: 1000000000000});
};