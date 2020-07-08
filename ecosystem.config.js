module.exports = {
  apps: [
    {
      name: 'iroha-node',
      script: 'app/bin/iroha-node',
      node_args: '-r esm',

      env: {
        NODE_ENV: 'development',
        IP: process.env.IP || '0.0.0.0',
        PORT: process.env.PORT || 10001,
        LOG_LEVEL: 'trace'
      }
    }
  ]
}
