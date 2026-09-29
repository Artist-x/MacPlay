import path from 'node:path'
const root = process.env.MACPLAY_RESOURCES || path.resolve(__dirname, '../..')
const gst = path.join(root, 'gstreamer/macos-arm64')
process.env.GST_PLUGIN_SYSTEM_PATH = ''
process.env.GST_PLUGIN_PATH = path.join(gst,'lib/gstreamer-1.0')
process.env.GST_PLUGIN_SCANNER = path.join(gst,'libexec/gstreamer-1.0/gst-plugin-scanner')
export const addon: any = require('livi-gst-video')
export const VIDEO_PLANE_MAIN = 1, VIDEO_PLANE_CLUSTER_RECV = 2
export type CpAudioCodec = 'aac-lc'|'opus'|'pcm'
export const gstHost: any = { onAudioStarted: () => {} }
let started: ((id:number,sample:number)=>void)|undefined
let player: any, aspect=16/9
export let onVideo: (()=>void)|undefined
export function setVideoCallback(callback:()=>void, ratio:number) { onVideo=callback; aspect=ratio }
export function openScreenReceiver(id:number,key:Buffer):number {
 return addon.openVideoReceiver(id,key,(codec:number,atom:Buffer)=>{
  if(player) addon.stop(player)
  const handle=addon.macplayWindowHandle(aspect)
  player=addon.createPlayer(codec===1?'h265':'h264',handle,atom,id)
  if(!player) throw new Error('无法创建CarPlay视频解码器')
  addon.start(player); addon.setContentRegion(player,0,0,aspect*1000,1000,aspect*1000,1000)
  onVideo?.()
 })
}
export function closeScreenReceiver(id:number) { addon.closeVideoReceiver(id); if(player){addon.stop(player);player=null} }
export function onAudioReceiverStarted(cb:(id:number,sample:number)=>void) {started=cb}
export function openAudioReceiver(key:Buffer,o:any):any {
 return addon.openAudioReceiver(key,o.codec,o.payloadType,o.clockRate,o.channels,o.latencyMs,o.realtime,o.device,(id:number,sample:number)=>started?.(id,sample))
}
export function closeAudioReceiver(id:number) {addon.closeAudioReceiver(id)}
export function setAudioReceiverActive(id:number,active:boolean) {addon.setAudioReceiverActive(id,active)}
export function setAudioReceiverVolume(id:number,level:number,ms:number) {addon.setAudioReceiverVolume(id,level,ms)}
export function openMicUplink(key:Buffer,o:any):number|null {return addon.openMicUplink(key,o.codec,o.payloadType,o.sampleRate,o.channels,o.bitrate,o.frameMs,o.port,o.phone,o.device)}
export function closeMicUplink(id:number){addon.closeMicUplink(id)}
