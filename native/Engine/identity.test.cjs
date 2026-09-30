const {test,after}=require('node:test');const assert=require('node:assert/strict');
const fs=require('node:fs');const os=require('node:os');const path=require('node:path');
const dir=fs.mkdtempSync(path.join(os.tmpdir(),'macplay-identity-'));process.env.MACPLAY_DATA=dir;
fs.mkdirSync(path.join(dir,'cp','macplay-v2'),{recursive:true});fs.writeFileSync(path.join(dir,'cp','macplay-v2','identity.json'),JSON.stringify({priv:'00'.repeat(32),pub:'00'.repeat(32),pi:'previous-mac-shared'}));fs.writeFileSync(path.join(dir,'cp','identity.json'),JSON.stringify({priv:'00'.repeat(32),pub:'00'.repeat(32),pi:'legacy-android-shared'}));
const modulePath=require.resolve('../../build/engine/protocol/identity.js');
let identity=require(modulePath);after(()=>fs.rmSync(dir,{recursive:true,force:true}));
test('MacPlay creates isolated persistent pairing identity',()=>{
 const first=identity.loadOrCreateIdentity();assert.notEqual(first.pairingId,'legacy-android-shared');assert.notEqual(first.pairingId,'previous-mac-shared');assert.equal(first.pubRaw.length,32);
 assert.ok(fs.existsSync(path.join(dir,'cp','macplay-v3','identity.json')));
 delete require.cache[modulePath];identity=require(modulePath);const second=identity.loadOrCreateIdentity();
 assert.equal(second.pairingId,first.pairingId);assert.deepEqual(second.pubRaw,first.pubRaw);
});
test('accessory address is stable and locally administered',()=>{
 const pub=Buffer.alloc(32,0xab);const id=identity.accessoryDeviceId(pub);assert.equal(id,'02:AB:AB:AB:AB:AB');
 assert.notEqual(id,identity.accessoryDeviceId(Buffer.alloc(32,0xcd)));assert.throws(()=>identity.accessoryDeviceId(Buffer.alloc(1)));
});
