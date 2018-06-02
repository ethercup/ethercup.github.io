var BetRegistry = artifacts.require("./BetRegistry.sol")
var Bet = artifacts.require("./BetDemo.sol") // remove Demo

module.exports = function(deployer, network, accounts) {
	
  const owner = accounts[0]

  var registry
  deployer.deploy(BetRegistry, {from: owner}).then(instance => {
    registry = instance
  }).catch(err => {
    console.log('Something went wrong while deploying the registry: ' + err)
  })

  deployer.deploy(
    Bet,
    0,
    '165069',
    'Group A', // 1/4 Final, 1/2 Final, 3rd Place, Final
    'Russia',
    'Saudi Arabia',
    true,
    1527963371,
    {from: owner, value: 1e16}
  ).then(bet => {
    console.log("bet deployed. now registering...at: " + registry.address)
    registry.addBet(bet.address, {from: owner});
    console.log('\n Successfully registered Bet (' + bet.address + ') in BetRegistry (' + registry.address + ')')
  }).catch(err => {
    console.log('Something went wrong: ' + err)
  })
};