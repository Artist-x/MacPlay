const {test}=require('node:test'),assert=require('node:assert/strict')
const {waitForMicrophone}=require('../../build/engine/microphonePermission')
test('late microphone grant cannot start a stopped session',async()=>{
 let current=true,resume,checks=0
 const pending=waitForMicrophone(()=>current,()=>{checks++;return 2},()=>new Promise(resolve=>resume=resolve))
 current=false;resume();assert.equal(await pending,false);assert.equal(checks,1)
})
test('grant applies only to the current session, denial finishes without polling',async()=>{
 let current=true
 assert.equal(await waitForMicrophone(()=>current,()=>1),true)
 assert.equal(await waitForMicrophone(()=>current,()=>0,()=>{throw Error('must not wait')}),false)
 assert.equal(await waitForMicrophone(()=>current,()=>{current=false;return 1}),false)
})
