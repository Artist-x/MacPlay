<p align="center"><img src="assets/icons/mac/macplay.iconset/icon_128x128.png" width="96" alt="MacPlay图标"></p>

# MacPlay

<p align="center">
  <a href="scripts/package-native.sh"><img src="https://img.shields.io/badge/version-1.0.0-2563eb?style=flat-square" alt="版本1.0.0"></a>
  <a href="#当前状态"><img src="https://img.shields.io/badge/macOS-14%2B-555555?style=flat-square" alt="macOS14及以上"></a>
  <a href="#当前状态"><img src="https://img.shields.io/badge/platform-Apple%20Silicon-555555?style=flat-square" alt="Apple Silicon平台"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-GPL--3.0--or--later-2563eb?style=flat-square" alt="GPL-3.0-or-later许可证"></a>
</p>

让Mac通过USB或共用Wi-Fi接收iPhone的CarPlay画面，提供原生macOS设置界面、分辨率选择与帧率请求。

基于LIVI改造，设置界面使用SwiftUI，视频窗口使用AppKit。

## 当前状态

当前版本为1.0.0，构建号12，支持运行macOS14及以上版本的Apple Silicon Mac。

有线与无线CarPlay连接均已在真实iPhone上跑通。无线使用Mac内置蓝牙完成连接引导，再通过共用Wi-Fi传输画面，无需LIVI Link。

- 通过USB数据线直连，或选择蓝牙配对与共用Wi-Fi连接。
- 支持屏幕原生像素、常用分辨率和自定义宽高。
- 普通视频窗口固定尺寸，允许拖动标题栏；原生模式默认全屏并避开刘海。
- 提供30fps、60fps、90fps和120fps请求上限，120fps视频启动失败时自动改用90fps重连一次。
- 取消界面倍率调节，按固定窗口对应的真实物理尺寸上报显示参数。

源码和DMG不包含认证文件，使用前须自行提供可用的配件认证材料。安装包采用本地签名，未经过Apple公证。

## 原生界面

设置窗口使用SwiftUI侧栏、分组表单、菜单、开关与滑块，投屏窗口使用AppKit。保留连接、显示、音频和诊断四页，移除Android Auto设置、仪表页面及Electron/React前端。Node.js作为辅助应用内的后台协议服务运行，不单独显示程序坞图标。

## 安装与连接

打开本地构建生成的`MacPlay-1.0.0-arm64.dmg`，将MacPlay拖入“应用程序”，启动后按需要允许本地网络、蓝牙和麦克风权限；读取Wi-Fi名称时另需定位授权。使用菜单退出应用。

### 有线

1. 用支持数据传输的USB线连接iPhone与Mac。
2. 解锁iPhone，在Finder和iPhone上完成“信任此电脑”。
3. 启动MacPlay，在“连接”页面选择“有线CarPlay”，点击“启动接收”或“应用并重新连接”，保持iPhone解锁，并确认出现的CarPlay连接提示。

有线后端通过macOS系统usbmuxd打开iPhone的carkit服务。若系统拒绝服务或USB网络接口不可用，连接不能继续；普通文件传输连接成功不代表CarPlay连接成功。

### 无线

1. Mac与iPhone加入同一个允许设备相互访问的Wi-Fi网络。
2. 打开“连接”，选择“无线CarPlay”，点击“读取当前网络”。macOS需要定位权限才能返回Wi-Fi名称；网络密码需自行填写。
3. 点击“启动接收”，再点击“打开蓝牙设置”，使Mac可被发现。
4. 在iPhone“设置→蓝牙”中选择Mac的系统名称，在两端确认配对码。
5. 回到MacPlay，点击“应用并重新连接”，在iPhone上打开“设置→通用→CarPlay”，确认连接提示。后端先通过蓝牙识别与认证，再转到Wi-Fi传输视频。

MacPlay使用Mac内置蓝牙，不会创建名为MacPlay的Wi-Fi。两端应连接同一个现有Wi-Fi。蓝牙页面显示Mac的系统名称，CarPlay接收端名称为MacPlay。有线模式仅启用USB连接后端，无线模式仅启用蓝牙连接后端。当前自动连接仅筛选名称含iPhone的已配对设备，请保留设备名称中的iPhone。

### 认证文件

认证文件独立保存在用户的应用支持目录`MacPlay/authentication`中，文件名为`identity.pk8`和`certificate.p7b`。可在“诊断”页面导入文件。

源码和DMG不包含认证私钥或证书。运行时需要自行提供有使用权限且互相匹配的文件。导入后，应用会在连接时使用这些文件完成配件认证。

## 分辨率与帧率

入口为侧栏“显示”。改变参数后点击“应用并重新连接”，使iPhone重新协商。

| 设置 | 可选值 |
| --- | --- |
| 分辨率 | 屏幕原生像素（避开刘海）、1280×720、1920×1080、2560×1440、3840×2160、自定义 |
| 最高帧率 | 30fps、60fps、90fps、120fps |

分辨率改变请求的视频像素尺寸。帧率是请求上限，不能保证iPhone实际输出对应帧数。

120fps自动回退仅在iPhone已发送RECORD建立会话后启用：15秒内没有视频配置，或出画面前会话结束，会把帧率选择改为90fps并重新连接一次。配对、认证失败和尚未建立会话不会触发；90fps不会继续循环重试。协议没有最高帧率接受确认，这一机制处理视频启动失败，不根据短时实测帧率降档。

原生模式优先读取主显示器的物理像素尺寸，读取失败时使用当前显示模式的像素尺寸；再按macOS提供的刘海安全区域换算并扣除对应像素，宽高向下取偶数。选择原生模式后，投屏窗口默认全屏并避开刘海。

其他分辨率保留完整视频像素，按视频像素占屏幕物理像素的比例换算固定窗口，允许拖动标题栏移动，禁止调整窗口大小。计算不把Retina倍率或系统缩放后的渲染分辨率当成真实屏幕尺寸；最终显示仍由macOS合成。超过当前屏幕可见区域的分辨率会提示无法按原尺寸显示，不自动缩小。鼠标坐标按实际画面区域换算。

已移除界面倍率调节。接收端只上报所选视频分辨率及固定窗口对应的真实物理尺寸，不使用假定DPI或人为倍率。系统无法返回真实尺寸时会提示错误。

请关闭CarPlay“设置→显示屏→智能缩放显示”。本次对照中，开启时iPhone原图为1250×786，关闭后的原图为3456×2170，与请求像素一致。该开关由iPhone控制，MacPlay没有远程修改它的接口。

## 从源码构建

在项目根目录操作。需要macOS、Xcode命令行工具、Node.js、pnpm、Rust、pkg-config和GStreamer开发SDK。GStreamer运行库随工程提供；编译仍需要开发头文件和pkg-config描述文件。

```sh
pnpm install
bash scripts/build-macplay.sh
```

构建输出在`dist`目录。脚本构建SwiftUI应用、蓝牙桥接程序、Rust连接后端、音视频模块和Node.js协议服务，再生成Apple Silicon DMG。未配置开发者证书时使用本地签名，不执行公证或发布。

## 开发记录

有线与无线连接已完成真机投屏，使用者确认无线连接时USB线未连接。关闭CarPlay智能缩放后的对照原图为3456×2170，与该次请求像素一致。2026-09-30，使用者确认当前应用已完全跑通。

9项显示参数测试覆盖5种分辨率与4档帧率的20组参数；6项回退测试覆盖超时、会话结束、视频到达、停止与90fps不重试等分支。媒体音量默认100%。

详细开发过程见[验证记录](docs/MACPLAY-VALIDATION.md)。其中早期构建的限制和问题属于历史记录，当前使用方式以本文为准。

## 来源与版权

MacPlay基于[LIVI](https://github.com/f-io/LIVI)修改，保留其许可证及原作者署名；连接和显示参数设计同时参考[DiPlay](https://github.com/shihabal3amri/DiPlay)与本地AndroidPlay实现。

项目沿用上游声明的GPL-3.0-or-later，完整条款见[LICENSE](LICENSE)。分发修改后的软件时，应按适用许可证提供相应源码与版权声明。第三方组件继续适用各自许可证，详见[NOTICE](NOTICE)。

MacPlay是独立衍生项目，不代表Apple或上游作者。CarPlay、iPhone、Mac及相关商标属于其权利人。开源代码许可不包含Apple认证材料、商标或第三方私钥的使用授权。
