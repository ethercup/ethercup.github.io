module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  networks: {
    dev: {
      host: "localhost",
      port: 8545,
      //from: "0x936e313c5941aaff6b887c93fd5e1f943d606bd8",
      network_id: "*", // match any network
      gas: 20e6
    },
    ropsten: {
      host: "localhost", // Connect to geth on the specified
      port: 8545,
      from: "0x4f3e7B7900e1352a43EA1a6aA8fc7F1FC03EfAc9", // default address to use for any transaction Truffle makes during migrations
      network_id: 3,
      gas: 4e6 // Gas limit used for deploys
    },
    kovan: {
      host: "localhost",
      port: 8545,
      from: "0x4f3e7B7900e1352a43EA1a6aA8fc7F1FC03EfAc9",
      network_id: 42,
      gas: 7e6 // 7999992
    },

    live: {
      host: "178.25.19.88", // Random IP for example purposes (do not use)
      port: 80,
      network_id: 1,        // Ethereum public network
      // optional config values:
      // gas
      // gasPrice
      // from - default address to use for any transaction Truffle makes during migrations
      // provider - web3 provider instance Truffle should use to talk to the Ethereum network.
      //          - function that returns a web3 provider instance (see below.)
      //          - if specified, host and port are ignored.
    },
  }//,
  //rpc: {
  //  host: 'localhost',
  //  post: 8080
  //}
};

