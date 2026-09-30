const {test}=require('node:test');const assert=require('node:assert/strict');
const {audioLevel,disconnectedAfterVideo}=require('../../build/engine/runtimeControls.js');
test('live levels preserve zero and clamp out-of-range values',()=>{assert.equal(audioLevel(0,1),0);assert.equal(audioLevel(0.45,1),0.45);assert.equal(audioLevel(2,1),1);assert.equal(audioLevel(-1,1),0)});
test('malformed live audio input retains previous level',()=>{assert.equal(audioLevel('bad',0.7),0.7);assert.equal(audioLevel(Infinity,0.2),0.2)});
test('disconnect stops established video but preserves negotiation fallback',()=>{assert.equal(disconnectedAfterVideo(true,false),true);assert.equal(disconnectedAfterVideo(false,false),false);assert.equal(disconnectedAfterVideo(true,true),false)});
