var Migrations = artifacts.require("./Migrations.sol");

module.exports = function(deployer, network, accounts) {


  console.log(accounts)

  deployer.deploy(
  	Migrations,
  	{from: accounts[0]}
  )
};
