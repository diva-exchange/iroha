/**
 * IrohaNode
 * Copyright(c) 2020 Konrad Baechler, https://diva.exchange
 * GPL3 Licensed
 */

'use strict'

import { Logger } from '@diva.exchange/diva-logger'
import net from 'net'
import { SocksClient } from 'socks'

const PORT_IROHA_INTERNAL = 10001

export class IrohaNode {
  /**
   * Factory
   *
   * @param port {number}
   */
  static make (port = PORT_IROHA_INTERNAL) {
    const _p = Math.floor(port)
    if (_p < 1025 || _p > 65535) {
      throw new Error('invalid port')
    }

    return new IrohaNode(_p)
  }

  /**
   * @param port {number}
   * @private
   */
  constructor (port) {
    this._mapNode = new Map([
      ['testnet-a', 'zmkwwarruox7i5ditmltnf4d36b7lwadk2egrcl3jhptpto4fplq.b32.i2p'],
      ['testnet-b', 'txbz37jbvotktzyjkzaauqzdzlpbkaqy7t5pml46mtv6pvlc2zmq.b32.i2p'],
      ['testnet-c', 'so2tld2bo4ghaydnz2fc2clclr4p5rw5ym5sby7drobzcnz57n6q.b32.i2p']
    ])

    this._port = port
    this._id = 1
    this._socket = new Map()

    this._createServer('172.18.1.1')
    this._createServer('172.18.2.1')
    this._createServer('172.18.3.1')
  }

  /**
   * @param ip {string}
   * @private
   */
  _createServer (ip) {
    net.createServer((c) => {
      let stream = null
      const id = this._id++
      Logger.trace('ID: ' + id + ' - Size: ' + this._socket.size)

      c.on('data', (data) => {
        let socket = null
        if (this._socket.has(id)) {
          socket = this._socket.get(id)
        }
        if (socket && !socket.destroyed) {
          if (!socket.write(data)) {
            socket.destroy()
          }
          return
        }

        stream = !stream ? data : Buffer.concat([stream, data])
        const match = stream.toString().match(/authority[^a-zA-Z0-9-]+([a-zA-Z0-9-]+)\.diva\.local/)
        if (match && match[1]) {
          Logger.trace('...looking for ' + match[1])
          if (this._mapNode.has(match[1])) {
            Logger.trace('Getting SocksClient for: ' + this._mapNode.get(match[1]))
            IrohaNode._getSocksClient(this._mapNode.get(match[1])).then((sock) => {
              socket = sock
              this._socket.set(id, socket)
              socket.on('error', (error) => {
                Logger.trace('SocksClient onError').error(error)
                socket.destroy()
              })
              socket.on('end', (data) => {
                Logger.trace('SocksClient onEnd, ' + id)
                data ? c.end(data) : c.end()
              })
              socket.on('close', () => {
                Logger.trace('SocksClient onClose, ' + id)
                this._socket.delete(id)
              })
              socket.on('data', (data) => {
                if (!c.write(data)) {
                  socket.destroy()
                }
              })

              if (!stream || !socket.write(stream)) {
                socket.destroy()
              }
              stream = null
            })
          } else {
            c.destroy()
          }
        }
      })
      c.on('end', (data) => {
        Logger.trace('C onEnd, ' + id)
        if (this._socket.has(id)) {
          data ? this._socket.get(id).end(data) : this._socket.get(id).end()
        }
      })
      c.on('close', () => {
        Logger.trace('C onClose, ' + id)
        if (this._socket.has(id)) {
          const socket = this._socket.get(id)
          socket.destroy()
        }
      })
      c.on('error', (error) => {
        Logger.trace('C onError').error(error)
        c.destroy()
      })
    })
      .listen(this._port, ip, () => {
        Logger.info(ip + ':' + this._port + ' listening')
      })
  }

  /**
   * @param addressB32
   * @returns {Promise<Socket>}
   * @private
   */
  static async _getSocksClient (addressB32) {
    const options = {
      proxy: {
        port: 4445,
        host: 'localhost', // ipv4 or ipv6 or hostname
        type: 5 // Proxy version (4 or 5)
      },
      destination: {
        port: 10001,
        host: addressB32
      },
      command: 'connect'
    }
    try {
      const info = await SocksClient.createConnection(options)
      return info.socket
    } catch (error) {
      Logger.error(error)
      throw new Error(error)
    }
  }
}

module.exports = { IrohaNode }
