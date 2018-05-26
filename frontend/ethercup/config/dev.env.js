'use strict'
const merge = require('webpack-merge')
const prodEnv = require('./prod.env')

module.exports = merge(prodEnv, {
  NODE_ENV: '"development"',
  NETWORK_ID: 42,
  ADDRESS_BET_REGISTRY: '"0x9540465c237EfB0C45a27741a845Ecb1558b878B"',
})
