const {test}=require('node:test');const assert=require('node:assert/strict');
const {FrameRateFallback}=require('../../build/engine/frameRateFallback.js');
test('120fps startup timeout retries once after RECORD',async()=>{let calls=0;const g=new FrameRateFallback(120,()=>calls++,5);g.sessionStarted();g.sessionStarted();await new Promise(r=>setTimeout(r,15));g.sessionEnded();assert.equal(calls,1)});
test('early session end after RECORD retries once',()=>{let calls=0;const g=new FrameRateFallback(120,()=>calls++);g.sessionStarted();g.sessionEnded();g.sessionEnded();assert.equal(calls,1)});
test('pairing failure before RECORD never retries',()=>{let calls=0;const g=new FrameRateFallback(120,()=>calls++);g.sessionEnded();assert.equal(calls,0)});
test('video arrival cancels fallback even if session later closes',async()=>{let calls=0;const g=new FrameRateFallback(120,()=>calls++,5);g.sessionStarted();g.videoStarted();g.sessionEnded();await new Promise(r=>setTimeout(r,15));assert.equal(calls,0)});
test('stop cancels pending retry',async()=>{let calls=0;const g=new FrameRateFallback(120,()=>calls++,5);g.sessionStarted();g.cancel();await new Promise(r=>setTimeout(r,15));assert.equal(calls,0)});
test('90fps failure cannot trigger another fallback',async()=>{let calls=0;const g=new FrameRateFallback(90,()=>calls++,5);g.sessionStarted();g.sessionEnded();await new Promise(r=>setTimeout(r,15));assert.equal(calls,0)});
