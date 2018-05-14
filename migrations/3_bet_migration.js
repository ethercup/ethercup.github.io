var BetRegistry = artifacts.require("./BetRegistry.sol")
var Bet = artifacts.require("./Bet.sol")

module.exports = function(deployer, network, accounts) {
	
  console.log(accounts)

  //Costs: 5720140, 5946030
  deployer.deploy(
  	Bet,
  	'165069',
    'A',
  	'Germany',
  	'Russia',
  	true,
  	1526295600,
  	3600*24*7,
  	3600*24,
  	{from: accounts[0], value: 1000000000000}
  )

};