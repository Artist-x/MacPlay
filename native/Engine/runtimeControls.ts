export function audioLevel(value:unknown,fallback:number):number {
 const n=Number(value);return Number.isFinite(n)?Math.max(0,Math.min(1,n)):fallback
}
/** Called only after a CarPlay RECORD session ends, never on authentication failure. */
export function disconnectedAfterSession(videoReady:boolean,stopping:boolean,fps:number):boolean {
 return !stopping && (videoReady || ![90,120].includes(fps))
}
