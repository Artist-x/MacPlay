export function audioLevel(value:unknown,fallback:number):number {
 const n=Number(value);return Number.isFinite(n)?Math.max(0,Math.min(1,n)):fallback
}
export function disconnectedAfterVideo(videoReady:boolean,stopping:boolean):boolean {return videoReady&&!stopping}
