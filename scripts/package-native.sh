#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
NODE_BIN="$(command -v node)"
APP="${MACPLAY_APP_OUTPUT:-$PWD/dist/MacPlay.app}"
RES="$APP/Contents/Resources"
RECEIVER="$RES/runtime/MacPlayReceiver.app"
mkdir -p "$APP/Contents/MacOS" "$RES/runtime" "$RES/engine/node_modules" "$RES/driver" "$RES/gstreamer"
cp build/MacPlay "$APP/Contents/MacOS/MacPlay"
mkdir -p "$RECEIVER/Contents/MacOS" "$RECEIVER/Contents/Resources"
cp "$NODE_BIN" "$RECEIVER/Contents/MacOS/MacPlayReceiver"
rm -f "$RES/runtime/node"
cp assets/icons/mac/macplay.icns "$RECEIVER/Contents/Resources/MacPlay.icns"
cat > "$RECEIVER/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>com.roylyl.macplay.receiver</string>
<key>CFBundleName</key><string>MacPlay</string><key>CFBundleDisplayName</key><string>MacPlay</string>
<key>CFBundleExecutable</key><string>MacPlayReceiver</string><key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.0.1</string><key>CFBundleVersion</key><string>20</string>
<key>CFBundleIconFile</key><string>MacPlay</string><key>LSMinimumSystemVersion</key><string>14.0</string>
<key>LSUIElement</key><true/><key>NSHighResolutionCapable</key><true/>
<key>NSLocalNetworkUsageDescription</key><string>MacPlay通过本地网络接收iPhone的CarPlay音视频。</string>
<key>NSMicrophoneUsageDescription</key><string>MacPlay使用麦克风进行语音控制和通话。</string>
</dict></plist>
PLIST
cp -R build/engine/. "$RES/engine/"
for mod in livi-crypto livi-gst-video; do
 mkdir -p "$RES/engine/node_modules/$mod/build/Release"
 cp "native/$mod/index.js" "native/$mod/package.json" "$RES/engine/node_modules/$mod/"
 cp "native/$mod/build/Release/"*.node "$RES/engine/node_modules/$mod/build/Release/"
done
cp native/livi-helperd/target/release/livi-helperd native/macplay-bluetooth/macplay-bluetooth "$RES/driver/"
if [[ ! -d "$RES/gstreamer/macos-arm64" ]]; then cp -R assets/gstreamer/macos-arm64 "$RES/gstreamer/"; fi
cp assets/icons/mac/macplay.icns "$RES/MacPlay.icns"
mkdir -p "$RES/icons"
cp assets/icons/carplay/macplay-256.png assets/icons/carplay/macplay-512.png "$RES/icons/"
cp LICENSE NOTICE "$RES/"
cp -R assets/licenses "$RES/ThirdParty-LICENSES"
cp -R assets/gstreamer/LICENSES "$RES/GStreamer-LICENSES"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>com.roylyl.macplay</string>
<key>CFBundleName</key><string>MacPlay</string><key>CFBundleDisplayName</key><string>MacPlay</string>
<key>CFBundleExecutable</key><string>MacPlay</string><key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.0.1</string><key>CFBundleVersion</key><string>20</string>
<key>CFBundleIconFile</key><string>MacPlay</string><key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSHighResolutionCapable</key><true/>
<key>NSBluetoothAlwaysUsageDescription</key><string>MacPlay通过Mac蓝牙与iPhone建立CarPlay连接。</string>
<key>NSLocalNetworkUsageDescription</key><string>MacPlay通过本地网络接收iPhone的CarPlay音视频。</string>
<key>NSLocationUsageDescription</key><string>macOS要求定位权限才能读取当前Wi-Fi名称。MacPlay仅用此权限读取网络信息，不保存位置信息。</string>
<key>NSLocationWhenInUseUsageDescription</key><string>macOS要求定位权限才能读取当前Wi-Fi名称。MacPlay仅用此权限读取网络信息，不保存位置信息。</string>
<key>NSMicrophoneUsageDescription</key><string>MacPlay使用麦克风进行Siri语音控制和通话。</string>
</dict></plist>
PLIST
ADDON="$RES/engine/node_modules/livi-gst-video/build/Release/gst_video.node"
while IFS= read -r rp; do install_name_tool -delete_rpath "$rp" "$ADDON"; done < <(otool -l "$ADDON" | awk '/LC_RPATH/{getline;getline;print $2}')
install_name_tool -add_rpath '@loader_path/../../../../../gstreamer/macos-arm64/lib' "$ADDON"
for bin in "$RECEIVER/Contents/MacOS/MacPlayReceiver" "$RES/driver/"* "$RES/engine/node_modules/"*/build/Release/*.node; do codesign --force --sign - "$bin"; done
codesign --force --sign - "$RECEIVER"
codesign --force --deep --sign - "$APP"
if [[ "${1:-}" != "--app-only" ]]; then
 mkdir -p build/dmg
 ln -sfn /Applications build/dmg/Applications
 rm -rf build/dmg/MacPlay.app
 ditto "$APP" build/dmg/MacPlay.app
 hdiutil create -ov -volname MacPlay -srcfolder build/dmg -format UDZO dist/MacPlay-1.0.1-arm64.dmg
fi
