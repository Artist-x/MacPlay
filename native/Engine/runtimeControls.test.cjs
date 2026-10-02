const {test}=require('node:test');const assert=require('node:assert/strict');
const {audioLevel,disconnectedAfterSession}=require('../../build/engine/runtimeControls.js');
test('live levels preserve zero and clamp out-of-range values',()=>{assert.equal(audioLevel(0,1),0);assert.equal(audioLevel(0.45,1),0.45);assert.equal(audioLevel(2,1),1);assert.equal(audioLevel(-1,1),0)});
test('malformed live audio input retains previous level',()=>{assert.equal(audioLevel('bad',0.7),0.7);assert.equal(audioLevel(Infinity,0.2),0.2)});
test('disconnect stops an established session at standard frame rates even before video',()=>{
 for(const fps of [30,60])assert.equal(disconnectedAfterSession(false,false,fps),true);
});
test('a high-frame-rate session failure preserves pre-video negotiation fallback',()=>{
 for(const fps of [90,120])assert.equal(disconnectedAfterSession(false,false,fps),false);
});
test('disconnect stops established video at any requested frame rate and avoids duplicate stop',()=>{
 for(const fps of [30,60,90,120]){
  assert.equal(disconnectedAfterSession(true,false,fps),true);
  assert.equal(disconnectedAfterSession(true,true,fps),false);
  assert.equal(disconnectedAfterSession(false,true,fps),false);
 }
});
