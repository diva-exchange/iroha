/**
 * IrohaNode
 * Copyright(c) 2020 Konrad Baechler, https://diva.exchange
 * GPL3 Licensed
 */

'use strict'

import { Logger } from '@diva.exchange/diva-logger'
import net from 'net'
import { SocksClient } from 'socks'

export class IrohaNode {
  /**
   * Factory
   *
   * @param ip {string} IP to listen on
   * @param port {number} Port to listen on, usually 10001
   */
  static make (ip, port) {
    const _p = Math.floor(port)
    if (_p < 1025 || _p > 65535) {
      throw new Error('invalid port')
    }

    return new IrohaNode(ip, _p)
  }

  /**
   * @param ip {string}
   * @param port {number}
   * @private
   */
  constructor (ip, port) {
    this._mapNode = new Map([
      ['testnet-a', 'aqloytaep2ishherz6opvcqlavel7bfztouwxv4oxev6gb2x2w6a.b32.i2p'],
      ['testnet-b', '3idwkryr4j2velfmcom5nuhg3353dd3omjo24nrdqb2oz72xkyoa.b32.i2p'],
      ['testnet-c', 'pnbtl2an4a43xqxdo4znfuqjsoetmugwpxoags4n2qc5aj5cblqq.b32.i2p']
    ])

    this._ip = ip
    this._port = port

    this._id = 1
    this._socket = new Map()

    this._waitForSocks()
  }

  /**
   * @private
   */
  _waitForSocks () {
    IrohaNode._getSocksClient('diva.i2p')
      .then(() => {
        this._createServer()
      })
      .catch(() => {
        Logger.trace('Socks not ready yet')
        setTimeout(() => { this._waitForSocks() }, 10000)
      })
  }

  /**
   * @private
   */
  _createServer () {
    net.createServer((c) => {
      let stream = null
      const id = this._id++

      // reuse of id's
      if (this._id > Math.pow(this._socket.size + 1, 3)) {
        this._id = 1
      }

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
            IrohaNode._getSocksClient(this._mapNode.get(match[1])).then((sock) => {
              socket = sock
              this._socket.set(id, socket)
              socket.on('error', (error) => {
                Logger.trace('SocksClient onError').error(error)
                socket.destroy()
              })
              socket.on('end', (data) => {
                data ? c.end(data) : c.end()
              })
              socket.on('close', () => {
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
              .catch((error) => {
                Logger.trace('Socks Error').error(error)
              })
          } else {
            c.destroy()
          }
        }
      })
      c.on('end', (data) => {
        if (this._socket.has(id)) {
          data ? this._socket.get(id).end(data) : this._socket.get(id).end()
        }
      })
      c.on('close', () => {
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
      .listen(this._port, this._ip, () => {
        Logger.info(this._ip + ':' + this._port + ' listening')
      })
  }

  /**
   * @param addressB32
   * @returns {Promise<Socket>}
   * @throws {Error} If Socks connection fails
   * @private
   */
  static async _getSocksClient (addressB32) {
    const options = {
      proxy: {
        port: 4445,
        host: 'i2p',
        type: 5 // Proxy version (4 or 5)
      },
      destination: {
        port: 10001,
        host: addressB32
      },
      command: 'connect'
    }
    const info = await SocksClient.createConnection(options)
    return info.socket
  }
}

module.exports = { IrohaNode }
