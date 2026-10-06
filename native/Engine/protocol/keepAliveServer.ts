import dgram from 'node:dgram'

export class KeepAliveServer {
  lastActivityNs=0n
  constructor(private peerHost='') {}
  private _sock: dgram.Socket | null = null

  listen(): Promise<number> {
    return new Promise((resolve, reject) => {
      const sock = dgram.createSocket({ type: 'udp6', ipv6Only: false })
      sock.on('error', reject)
      sock.on('message', (msg, peer) => {if(msg.length && peer.address.replace(/^::ffff:/,'').split('%')[0]===this.peerHost.replace(/^::ffff:/,'').split('%')[0])this.lastActivityNs=process.hrtime.bigint()})
      sock.bind(0, '::', () => {
        this._sock = sock
        resolve(sock.address().port)
      })
    })
  }

  stop(): void {
    this._sock?.close()
    this._sock = null
  }
}
