var BetManager = artifacts.require("./BetManager.sol")
var Bet = artifacts.require("./Bet.sol")


module.exports = function(deployer, network, accounts) {
	

  //deployer.deploy(
  //	BetManager,
  //	{from: '0x3cea651fcb39719ff6a3c9c5fae2d3d5cef87fdf'}
  //)



  // Costs: 5720140, 5946030
  deployer.deploy(
  	Bet,
  	'165069',
  	'Germany',
  	'Russia',
  	true,
  	1525804927,
  	3600*24,
  	3600*24//,
  	//{from: '0x3cea651fcb39719ff6a3c9c5fae2d3d5cef87fdf', value: 1000000000000}
  )

  

};