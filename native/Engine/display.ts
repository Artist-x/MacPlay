import type { CpDisplayConfig } from './protocol/types'
interface DisplaySettings {
 width:number; height:number; fps:number
 screenPixelWidth:number; screenPixelHeight:number
 screenWidthMm:number; screenHeightMm:number
}
export function displayConfig(settings: DisplaySettings): CpDisplayConfig {
 const width=Math.max(320,Math.min(7680,Math.round(settings.width/2)*2))
 const height=Math.max(200,Math.min(4320,Math.round(settings.height/2)*2))
 for(const value of [settings.screenPixelWidth,settings.screenPixelHeight,settings.screenWidthMm,settings.screenHeightMm]) {
  if(!Number.isFinite(value)||value<=0)throw new Error('无法读取显示器真实像素或物理尺寸，请重新启动MacPlay读取屏幕信息。')
 }
 const fps=[30,60,90,120].includes(settings.fps)?settings.fps:60
 // The fixed window occupies this same fraction of the physical panel.
 // Report its actual size; never invent a DPI or apply a UI multiplier.
 const widthPhysicalMm=Math.max(1,Math.round(settings.screenWidthMm*width/settings.screenPixelWidth))
 const heightPhysicalMm=Math.max(1,Math.round(settings.screenHeightMm*height/settings.screenPixelHeight))
 return {widthPixels:width,heightPixels:height,widthPhysicalMm,heightPhysicalMm,fps,primaryInputDevice:1,viewArea:{top:0,bottom:0,left:0,right:0},safeArea:{top:0,bottom:0,left:0,right:0},safeAreaDrawOutside:true}
}
