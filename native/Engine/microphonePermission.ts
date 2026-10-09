// Cancel permission waiting without allowing a late grant to start an old session.
export async function waitForMicrophone(current:()=>boolean, permission:()=>number,
 sleep:(ms:number)=>Promise<void> = ms=>new Promise(resolve=>setTimeout(resolve,ms))) {
 while(current()) {
  const status=permission()
  if(status!==2)return status===1&&current()
  await sleep(200)
 }
 return false
}
