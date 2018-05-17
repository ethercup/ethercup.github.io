var BetRegistry = artifacts.require("./BetRegistry.sol")
var Bet = artifacts.require("./Bet.sol")

module.exports = function(deployer, network, accounts) {
	
  console.log(accounts[0])

  //Costs: 5720140, 5946030, 5938263, 6138904, 6469017

  // Bet (matchstart: 1526486400):
  // 0xada59dd51d20f16d3a2d7aca19ad88ff62664dba

  deployer.deploy(
  	Bet,
  	'165069',
    'A',
  	'Germany',
  	'Russia',
  	false,
  	1526486400,
  	3600*24*7,
  	3600*24,
  	{from: accounts[0], value: 1e17}
  )

};