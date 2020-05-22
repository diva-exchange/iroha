/*!
 * iroha proxy server for outgoing traffic
 * Copyright(c) 2020 Konrad Baechler, https://diva.exchange
 * GPL3 Licensed
 */

'use strict'

import net from 'net'

const LOCAL_PORT  = 10001
const REMOTE_PORT = 10011
const REMOTE_ADDR = {
  'holodeck0.diva.local': '172.18.0.12',
  'holodeck1.diva.local': '172.18.1.12',
  'holodeck2.diva.local': '172.18.2.12'
}

const server = net.createServer((socketLocal) => {
  let dataStream = null
  let socketRemote = null

  socketLocal.on('data', (dataFromLocal) => {
    if (!dataStream) {
      dataStream = dataFromLocal
    } else {
      dataStream = Buffer.concat([dataStream, dataFromLocal])
    }
    if (!socketRemote) {
      const match = dataStream.toString().match(/([a-z0-9]+\.diva\.local):[\d]+/)
      if (match && match[1] && REMOTE_ADDR[match[1]]) {
        socketRemote = new net.Socket()
        socketRemote.setTimeout(60000)
        socketRemote.on('error', (error) => {
          console.log('** ERROR socketRemote', error)
          socketLocal.destroy()
          socketRemote.destroy()
          socketRemote = null
        })
        socketRemote.on('data', (dataFromRemote) => {
          if (!socketLocal.write(dataFromRemote)) {
            console.log('** ERROR writing to socketLocal')
            socketLocal.destroy()
            socketRemote.destroy()
            socketRemote = null
          }
        })

        socketRemote.connect({
            port: REMOTE_PORT,
            host: REMOTE_ADDR[match[1]]
          },
          () => {
            if (!socketRemote.write(dataStream)) {
              console.log('** ERROR writing to socketRemote')
              socketLocal.destroy()
              socketRemote.destroy()
              socketRemote = null
            } else {
              dataStream = null
            }
        })
      }
    } else {
      if (!socketRemote.write(dataStream)) {
        console.log('** ERROR writing to socketRemote')
        socketLocal.destroy()
        socketRemote.destroy()
        socketRemote = null
      } else {
        dataStream = null
      }
    }
  })

  socketLocal.on('end', (dataFromLocal) => {
    if (dataFromLocal) {
      if (!dataStream) {
        dataStream = dataFromLocal
      } else {
        dataStream = Buffer.concat([dataStream, dataFromLocal])
      }
    }
    if (dataStream && socketRemote) {
      socketRemote.write(dataStream, () => {
        socketRemote.destroy()
        socketRemote = null
      })
      dataStream = null
    }
  })

  socketLocal.on('error', (error) => {
    console.log('** ERROR socketLocal', error)
    socketLocal.destroy()
    if (socketRemote) {
      socketRemote.destroy()
      socketRemote = null
    }
  })
})

server.listen(LOCAL_PORT)
console.log("TCP server accepting connection on port: " + LOCAL_PORT)
