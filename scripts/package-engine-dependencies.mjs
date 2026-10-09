import fs from 'node:fs'
import path from 'node:path'
import {createRequire} from 'node:module'
const destination=process.argv[2]
if(!destination)throw new Error('Missing engine node_modules destination')
const installed=new Set()
function copy(name,requireFrom) {
 if(installed.has(name))return
 const entry=requireFrom.resolve(name)
 let root=path.dirname(entry)
 while(!fs.existsSync(path.join(root,'package.json'))||JSON.parse(fs.readFileSync(path.join(root,'package.json'),'utf8')).name!==name) {
  const parent=path.dirname(root);if(parent===root)throw new Error('Cannot locate '+name);root=parent
 }
 const manifest=JSON.parse(fs.readFileSync(path.join(root,'package.json'),'utf8'))
 const target=path.join(destination,name)
 fs.mkdirSync(path.dirname(target),{recursive:true})
 fs.cpSync(root,target,{recursive:true,filter:source=>path.basename(source)!=='node_modules'})
 installed.add(name)
 const local=createRequire(path.join(root,'package.json'))
 for(const dependency of Object.keys(manifest.dependencies||{}))copy(dependency,local)
}
copy('multicast-dns',createRequire(import.meta.url))
