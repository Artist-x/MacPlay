// A maxFPS request has no acceptance ACK. Retry only after RECORD, before video.
export class FrameRateFallback {
 private timer: ReturnType<typeof setTimeout> | undefined
 private armed=false
 private finished=false
 constructor(private fps:number, private retry:()=>void, private delayMs=15000) {}
 sessionStarted() {
  if(this.fps!==120 || this.finished || this.armed)return
  this.armed=true
  this.timer=setTimeout(()=>this.fail(),this.delayMs)
 }
 videoStarted(){this.cancel()}
 sessionEnded(){if(this.armed)this.fail();else this.cancel()}
 cancel(){this.finished=true;this.armed=false;if(this.timer)clearTimeout(this.timer);this.timer=undefined}
 private fail(){if(!this.armed||this.finished)return;this.cancel();this.retry()}
}
