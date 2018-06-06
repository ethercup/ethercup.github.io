var BetRegistry = artifacts.require("./BetRegistry.sol")
var Bet = artifacts.require("./Bet.sol")
var OraclizeLib = artifacts.require("./oraclizeLib.sol")

module.exports = function(deployer, network, accounts) {
	
  const owner = accounts[0]

  let registry
  deployer.deploy(BetRegistry, {from: owner}).then(instance => {
    registry = instance
    console.log('registry created.')
  }).catch(err => {
    console.log('Something went wrong while deploying the registry: ' + err)
  })

  deployer.deploy(OraclizeLib)
  deployer.link(OraclizeLib, Bet)

  deployer.deploy(
    Bet,
    0,
    '165069',
    'Group A', // 1/4 Final, 1/2 Final, 3rd Place, Final
    'Russia',
    'Saudi Arabia',
    true,
    1528225200,
    {from: owner, value: 1e16}
  ).then(bet => {
    console.log(bet)
  }).catch(err => {
    console.log('Something went wrong: ' + err)
  })
  
};