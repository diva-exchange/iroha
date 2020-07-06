module.exports = {
  apps: [
    {
      name: 'iroha-node',
      script: 'app/bin/iroha-node',
      node_args: '-r esm',

      env: {
        NODE_ENV: 'development',
        IDENT: process.env.IDENT || 'testnet-a',
        PORT_IROHA_INTERNAL: process.env.PORT_IROHA_INTERNAL || 10001,
        LOG_LEVEL: 'trace'
      }
    }
  ]
}
