'use strict'
const merge = require('webpack-merge')
const prodEnv = require('./prod.env')

module.exports = merge(prodEnv, {
  NODE_ENV: '"development"',
  NETWORK_ID: 42,
  ADDRESS_OWNER: '"0x4f3e7b7900e1352a43ea1a6aa8fc7f1fc03efac9"', // must be lowercase
  ADDRESS_BET_REGISTRY: '"0x1b7648968048dd09f996ea1afc327acf91d9bb21"',
  GAS_DEFAULT: 190000,
  GAS_BET: 90000,
  GAS_FUND: 80000, // TODO: doublecheck this
  GASPRICE_DEFAULT: 6e9,
  ETHERSCAN_URL: '"https://kovan.etherscan.io/address/"',
  ETHERSCAN_APPENDIX: '"#code"'
})
