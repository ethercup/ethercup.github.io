var BetRegistry = artifacts.require("./BetRegistry.sol")
var Bet = artifacts.require("./Bet.sol")

module.exports = function(deployer, network, accounts) {
	
  const owner = accounts[0]

  var registry
  // deployer.deploy(
  //   BetRegistry,
  //   {from: owner}
  // ).then(r => {
  //   registry = r
  // })
  BetRegistry.deployed().then(function(instance) {
    registry = instance;
  }).then(function(result) {
    console.log("bet registry instance available.")
    //Costs: 6280953
    deployer.deploy(
      Bet,
      0,
      '165069',
      'Group A', // 1/4 Final, 1/2 Final, 3rd Place, Final
      'South Korea',
      'Costa Rica',
      true,
      1527436800,
      3600*24,
      3600*24,
      {from: owner, value: 1e16}
    ).then(bet => {
      console.log("bet deployed. now registering...at: " + registry.address)
      registry.addBet(bet.address, {from: owner});
      console.log('\n Successfully registered Bet (' + bet.address + ') in BetRegistry (' + registry.address + ')')
    })


  });
};