const path = require('path')

const addonPath = path.join(__dirname, 'build', 'Release', 'gst_video.node')

let addon
if (process.platform === 'linux') {
  const os = require('os')
  const dl = os.constants.dlopen
  const mod = { exports: {} }
  process.dlopen(mod, addonPath, dl.RTLD_LAZY | dl.RTLD_DEEPBIND)
  addon = mod.exports
} else {
  addon = require(addonPath)
}

const macplayWindowPath = path.join(__dirname, 'build', 'Release', 'macplay_window.node')
try {
  const fs = require('fs')
  if (fs.existsSync(macplayWindowPath)) {
    const macplay = require(macplayWindowPath)
    addon = Object.assign({}, addon, macplay)
  }
} catch (e) {
  console.error('[livi-gst-video] optional macplay_window load error:', e)
}

module.exports = addon
