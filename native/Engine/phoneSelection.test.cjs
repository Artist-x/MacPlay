const {test}=require('node:test')
const assert=require('node:assert/strict')
const {acceptsPhone}=require('../../build/engine/phoneSelection.js')
test('selected phone accepts normalized Bluetooth identity and rejects another phone',()=>{
 assert.equal(acceptsPhone('AA:BB:CC:DD:EE:FF','aa-bb-cc-dd-ee-ff',false),true)
 assert.equal(acceptsPhone('AA:BB:CC:DD:EE:FF','00:11:22:33:44:55',false),false)
})
test('automatic first connection accepts a phone, while an occupied session rejects competitors',()=>{
 assert.equal(acceptsPhone(undefined,'aa:bb:cc:dd:ee:ff',false),true)
 assert.equal(acceptsPhone(undefined,'aa:bb:cc:dd:ee:ff',true),false)
})
