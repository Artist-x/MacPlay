<p align="center"><img src="assets/icons/mac/macplay.iconset/icon_128x128.png" width="96" alt="MacPlay图标"></p>

<h1 align="center">MacPlay</h1>

<p align="center">让Mac通过USB或蓝牙配对与共用Wi-Fi接收iPhone的CarPlay画面，无需外接CarPlay适配器。</p>

<p align="center">
  <a href="scripts/package-native.sh"><img src="https://img.shields.io/badge/version-1.0.1-2563eb?style=flat-square" alt="版本1.0.1"></a>
  <a href="#使用条件"><img src="https://img.shields.io/badge/macOS-14%2B-555555?style=flat-square" alt="macOS14及以上"></a>
  <a href="#使用条件"><img src="https://img.shields.io/badge/platform-Apple%20Silicon-555555?style=flat-square" alt="Apple Silicon"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-GPL--3.0--or--later-2563eb?style=flat-square" alt="GPL-3.0-or-later"></a>
</p>

<p align="center"><a href="#安装与首次连接">安装与首次连接</a> · <a href="#功能">功能</a> · <a href="#常见问题">常见问题</a> · <a href="#从源码构建">从源码构建</a> · <a href="#来源与许可">来源与许可</a></p>

**开始使用前，需要自行提供有使用权限且互相匹配的配件认证证书与私钥**。公开源码和DMG不包含认证材料；缺少它们时，应用能够打开，但无法建立CarPlay连接。

当前版本为1.0.1，构建号20。基于LIVI改造，设置界面使用SwiftUI，视频窗口使用AppKit。有线与无线CarPlay连接均已在真实iPhone上跑通；这不代表所有Mac、iPhone与iOS版本均已验证。

## 使用条件

| 项目 | 要求 |
| --- | --- |
| Mac | Apple Silicon，macOS14及以上；未提供Intel版 |
| iPhone | 支持CarPlay；连接时解锁并确认系统提示 |
| 配件认证 | 自行提供`identity.pk8`与`certificate.p7b`，且有权用于该用途 |
| 有线连接 | 支持数据传输的USB线，完成“信任此电脑” |
| 无线连接 | 两端完成蓝牙配对，并加入允许设备互访的同一个Wi-Fi |
| 网络凭据 | 填写SSID与共享密码；可授权读取Mac已保存的Wi-Fi密码 |

DMG包含Node.js与GStreamer运行组件，使用安装包无需另装开发工具。当前包采用本地签名，未经过Apple公证。

## 安装与首次连接

1. 获取`MacPlay-1.0.1-arm64.dmg`，打开后将MacPlay拖入“应用程序”。GitHub源码ZIP不能直接作为应用运行。
2. 启动MacPlay。如果系统拦截，在“系统设置→隐私与安全性”中检查并允许打开该应用。
3. 在“诊断”页面导入`identity.pk8`与`certificate.p7b`。文件保存在本机应用支持目录的`MacPlay/authentication`中，不上传到服务器。
4. 按以下步骤选择有线或无线连接。首次出现权限、信任或配对提示时，在Mac和iPhone上确认。

### 认证材料从哪里获取

MacPlay当前没有获准公开分发的认证材料下载地址。仅下载DMG或注册Apple开发者账号，不会自动获得本程序需要的证书和私钥。

1. **已有CarPlay配件或方案授权**：联系原配件厂商或认证方案供应商，说明接收端为MacPlay、采用本地文件签名，申请明确允许这一用途的配套材料。购买配件本身不等于获准导出或复用其认证身份。
2. **商业产品开发**：通过[Apple MFi官方入口](https://mfi.apple.com/)与[官方FAQ](https://mfi.apple.com/en/faqs)确认参与资格及适用认证方案。MFi加入和认证是申请流程，不是通用私钥下载服务；最终方案也可能使用硬件认证，而不提供MacPlay所需的文件。
3. **已有合法授权的配套文件**：向提供方确认文件格式、适用产品、使用范围和是否允许本地软件签名，再按下表导入。不要把证书、私钥发到GitHub Issues或聊天中。

| 文件 | 当前实现读取的格式 |
| --- | --- |
| `identity.pk8` | DER编码的PKCS#8 P-256私钥 |
| `certificate.p7b` | 提供方配套的配件证书数据，需与私钥匹配并被iPhone接受 |

进入“诊断→导入认证文件”，选择这两份文件，然后重新启动接收。其他产品的证书、Apple开发者签名证书和自行生成的密钥不能直接视为可用CarPlay配件身份。没有获准使用的材料时，可安装和查看设置，但当前版本不能完成CarPlay连接。

### 有线CarPlay

1. 用USB数据线连接iPhone与Mac，解锁iPhone，在Finder和iPhone上完成信任确认。
2. 在MacPlay“连接”页面选择“有线CarPlay”。多台iPhone同时接入时，在“iPhone”列表中选择目标设备。
3. 点击“启动接收”或“应用并重新连接”，在iPhone上确认CarPlay提示，等待画面出现。

有线连接不需要填写Wi-Fi信息。后端通过macOS系统usbmuxd打开iPhone的carkit服务；仅在Finder中看到手机，不代表CarPlay会话已建立。

### 无线CarPlay

1. Mac与iPhone加入同一个允许设备互访的Wi-Fi，选择“无线CarPlay”。
2. 点击“读取当前网络”。macOS要求定位权限才能返回Wi-Fi名称；若无法读取，可手动填写SSID。
3. 填写网络密码，或点击“读取已保存密码”并按钥匙串提示授权。系统钥匙串可能要求管理员用户名与登录密码；这里不是填写Wi-Fi用户名。读取成功后无需日常重复授权。
4. 点击“打开蓝牙设置”，在iPhone“设置→蓝牙”中选择Mac的系统名称，在两端确认配对码。首次发现建议保留iPhone设备名称中的“iPhone”。
5. 在MacPlay选择目标iPhone，点击“应用并重新连接”，再在iPhone“设置→通用→CarPlay”中确认连接。

MacPlay使用Mac内置蓝牙引导连接，然后通过Wi-Fi传输音视频，不创建名为MacPlay的热点。蓝牙页面显示Mac的系统名称，CarPlay入口名称为MacPlay。

当前握手使用SSID与共享密码，不支持发送802.1X企业Wi-Fi的用户名、个人密码或证书。检测到当前网络采用企业认证时，应用会提示改用个人Wi-Fi、热点或USB。网页登录凭据也不是Wi-Fi共享密码，程序不会读取网页登录密码。访客网络、客户端隔离或网络防火墙可能阻止连接。

### 选择与记忆iPhone

“自动（上次连接的iPhone）”使用上次收到视频配置的设备记录，兼用于有线和无线。目标设备不在时不会自动切换到另一台；需要切换时，从列表中选择设备，再点击“应用并重新连接”。

列表包含已识别的蓝牙配对设备、USB接入设备和历史连接设备。同名设备附有标识末尾。某台iPhone仅连接过无线、尚无USB记录时，第一次有线连接需要手动选择其USB条目，成功后关联记录。

## 功能

- 原生设置界面：连接、显示、音频和诊断四页。
- 有线与无线接收：有线使用系统USB服务，无线使用内置蓝牙与共用Wi-Fi。
- 分辨率：屏幕原生像素（避开刘海）、1280×720、1920×1080、2560×1440，以及自定义宽高。
- 固定视频窗口：允许拖动标题栏，禁止调整窗口大小；原生像素模式默认全屏并避开刘海。
- 触控板：点击、拖动、双指滚动；双指滚动转换为CarPlay单指滑动，方向遵循系统自然滚动设置。
- 音频：播放音量默认100%，可在音频页面调整。
- 设备选择：默认上次连接的iPhone，可手动选择其他已识别设备。

### 分辨率与帧率

选择显示参数后点击“应用并重新连接”，使iPhone重新协商。视频像素与固定窗口的真实物理尺寸分别上报，不提供界面倍率调节。普通窗口按视频像素占屏幕物理像素的比例计算；超过可见区域时提示错误，不自动缩小。

请关闭CarPlay“设置→显示屏→智能缩放显示”。此前对照中，开启时iPhone原图为1250×786，关闭后的原图为3456×2170，与该次请求像素一致。MacPlay没有远程修改这一开关的接口。

| 帧率请求 | 回退行为 |
| --- | --- |
| 30fps、60fps | 不自动降档 |
| 90fps | 视频启动协商失败后改用60fps |
| 120fps | 视频启动协商失败后依次改用90fps、60fps |

发起CarPlay启动协商后20秒内未收到视频配置，或视频启动前会话结束，触发一次降档重连；60fps不再降档。认证前失败、主动停止及已启动视频后的普通断线不触发降档。

90/120fps是实验请求，不能保证iPhone实际输出对应帧率。出现CarPlay Ultra选项也不能证明当前远程视频流支持高帧率。首次连接建议使用60fps。参考[Apple的下一代CarPlay架构说明](https://developer.apple.com/videos/play/wwdc2024/10111/)。

## 常见问题

| 现象 | 检查方法 |
| --- | --- |
| 提示缺少认证文件 | 在诊断页面导入两份匹配且获准使用的认证文件；安装包不会自动生成它们 |
| USB未识别或无法启动CarPlay | 更换数据线，解锁iPhone并确认信任；检查USB设备和连接阶段 |
| 无线一直等待连接 | 检查配对、目标iPhone、SSID、密码及设备互访；不要寻找“MacPlay”Wi-Fi |
| 读不到Wi-Fi名称 | 允许MacPlay定位权限，重新读取；仍失败时手动输入SSID |
| 密码读取要求管理员授权 | 按macOS钥匙串提示操作，或手动填写一次；不是每次连接都要读取钥匙串 |
| 图标很大、原图像素低于请求 | 关闭CarPlay自身的智能缩放显示，再对照截图与诊断记录 |
| 自定义分辨率无法启动 | 选择较低分辨率或原生像素模式，确认窗口能按物理像素比例放入屏幕 |
| 选择设备后没有连接 | 确认所选设备已接入或配对，再应用设置；自动模式不会改连其他设备 |

通过应用菜单退出。更新时退出旧版后替换应用，认证与设置保留在本机应用支持目录。要彻底移除个人配置，可退出应用后手动删除该目录；仅删除应用不会清除已保存的Wi-Fi密码和配对记录。

## 数据与权限

网络密码、设备记录和配对密钥保存在本机应用支持目录，设置文件权限限制为当前用户读写。密码读取由macOS钥匙串授权控制，密码不输出到程序日志。

- 定位权限仅用于读取Wi-Fi信息，位置回调不保存坐标。
- 蓝牙和本地网络用于连接iPhone；麦克风用于通话及语音上行。
- 协议日志可能包含设备名称、地址和网络信息，分享诊断前应检查并遮盖个人数据。
- README徽章由Shields.io加载，运行应用本身不依赖徽章服务。

## 从源码构建

需要macOS、Xcode命令行工具、Node.js、pnpm、Rust、pkg-config与GStreamer开发SDK。将开发SDK的`lib/pkgconfig`加入`PKG_CONFIG_PATH`；打包时使用工程中的GStreamer运行库。

在仓库根目录运行：

```sh
pnpm install
pnpm run build
```

输出为`dist/MacPlay.app`与`dist/MacPlay-1.0.1-arm64.dmg`。脚本构建SwiftUI应用、蓝牙桥接程序、Rust连接后端、音视频模块和Node.js协议服务，再执行本地签名和DMG打包，不提交或发布。

编译协议服务并运行现有针对性测试：

```sh
pnpm run build:engine
pnpm test
```

运行库的许可证在`assets/licenses`与`assets/gstreamer/LICENSES`中。分发修改版时，需同时满足应用及第三方组件的许可证条件，提供发行二进制对应的源码和构建资料。

## 验证范围

有线与无线已在真实iPhone上显示CarPlay，使用者确认无线测试时USB未连接。关闭智能缩放后的原图曾达到3456×2170。

当前20项针对性测试通过，覆盖显示参数、帧率回退、持久化身份与目标设备匹配。构建20的编译和DMG打包已完成；密码读取已根据使用者反馈恢复此前可用路径。多台真机切换、企业Wi-Fi检测和全新Mac首次安装尚未完成独立实测，不作全设备兼容保证。

详细记录见[开发验证记录](docs/MACPLAY-VALIDATION.md)与[1.0.1发布检查](docs/RELEASE-1.0.1.md)。

## 来源与许可

MacPlay直接基于[LIVI](https://github.com/f-io/LIVI)，保留Lasse Heitgres及贡献者的版权与许可声明。连接、认证及显示参数同时参考[DiPlay](https://github.com/shihabal3amri/DiPlay)和本地AndroidPlay衍生实现。来源说明见[NOTICE](NOTICE)。

项目沿用上游声明的GPL-3.0-or-later，条款见[LICENSE](LICENSE)。第三方组件继续适用各自许可证；开源代码许可不包含配件认证证书、私钥、Apple商标或其他第三方材料的授权。

MacPlay为独立衍生项目，不代表Apple或上游作者，不声称获得MFi认证，也不声称是历史上首个Mac CarPlay接收端。CarPlay、iPhone与Mac等商标属于其权利人，用于说明兼容对象。请勿在仓库、发行附件或问题报告中上传认证私钥、网络密码和私人配对记录。
