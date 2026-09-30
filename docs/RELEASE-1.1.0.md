# MacPlay1.1.0验证记录

2026-09-30，构建25。本地修改，未提交或发布。

- Swift、TypeScript、Rust和原生窗口模块编译通过，DMG构建完成。
- 首次安装默认值调整为1280×720、60fps，已有设置不重置；此项修改后仅重新编译Swift应用并打包DMG，未重复构建未修改的协议与原生模块。
- 23项针对性测试覆盖既有显示/帧率/设备选择及新增音量边界和断开条件。
- 内建显示器参数、输入输出设备读取和原生设置界面已检查。
- 认证文件按维护者本次要求加入源码与包，来源DiPlay0.2.6，公开再分发授权尚未独立确认；不表示Apple/MFi认证。
- 歌曲、封面和状态由iAP2事件接入MPNowPlayingInfoCenter，媒体按键通过CarPlay HID发送。
- 歌词：当前协议没有提供歌词字段，控制中心没有公开歌词展示接口，本版不宣称支持。
- 外接多屏、通话实际音量、控制中心真实歌曲以及真实iPhone被动断开仍需设备验证；编译与单元测试不替代这些实测。
- README与更新日志的离线校验为0错误、0警告；README使用CommonMark与表格扩展生成预览，标题、表格与加粗解析正常。浏览器首屏和窄屏视觉检查未完成，此记录不把HTML解析检查写成浏览器验证。

## 滚动与系统媒体修复

- 修正NSEvent垂直滚动量到CarPlay触摸坐标的方向，C++滚动回归检查通过。
- 新增独立Swift播放状态模型，覆盖封面先到、增量元数据、旧封面迟到、封面编号复用、暂停/继续播放、跳转后旧进度回流及歌曲切换，回归检查通过。
- Rust模拟会话验证目标位置编码为`SetNowPlayingInformation(0x5003)`并发到手机端，过期歌曲请求不发送；元数据订阅重放检查通过。这是协议模拟验证，未替代实际iPhone和控制中心拖动测试。
- 向iPhone订阅播放速率、歌曲身份和`PlaybackSetElapsedTimeAvailable`，按能力启用Mac系统进度条拖动。
- Apple接入说明：[changePlaybackPositionCommand](https://developer.apple.com/documentation/mediaplayer/mpremotecommandcenter/changeplaybackpositioncommand)。iAP2字段与消息编号核对来源：[Nocturne的Now Playing协议定义](https://github.com/usenocturne/nocturne/blob/main/crates/iap2/src/csm/now_playing.rs)，查阅日期2026-09-30；实现沿用本工程的CSM编码与会话循环，未引入该项目作为依赖。

## 媒体数据传输修复

- 现场检查确认iAP2接收端已有封面、375秒总时长、持续更新的播放位置和跳转权限；旧构建的系统媒体信息却缺少封面、时长与进度，并被标记为直播。
- 主窗口改为直接订阅接收端本地套接字，在视频建立后重放缓存，再按接收顺序处理媒体增量；封面与进度不再通过合并stdout/stderr的日志管道传输。
- 使用当前已连接iPhone的实际媒体数据验证新订阅实现：总时长、播放位置、可解码封面及跳转权限均成功读取。该检查没有重启或操作用户的CarPlay会话，也没有向系统发布测试媒体信息。
- 新增分片传输回归，覆盖大封面跨读取边界、JSON整数与后续进度增量；Swift与TypeScript编译通过。
- 更新后的控制中心视觉展示和实际拖动仍需在启动构建22后验证，以上接收检查不代表已完成系统界面验证。

## 主题设置

- 显示页新增深色模式、浅色模式、跟随系统，默认跟随Mac。旧设置缺少主题字段时使用跟随系统，不重置其他设置。
- 主窗口使用对应外观；通过AppKit观察Mac外观变化，并实时向现有CarPlay会话发送setNightMode。初始主题在RECORD后发送，避免协商前发送外观命令。
- Swift与TypeScript编译通过；未切换用户Mac的全局外观，也未重启当前CarPlay会话，主题切换的实际显示尚未进行设备验证。

## 文档同步

- README与仓库、桌面TXT教程同步至构建25，补充主题、跟随Mac外观、CarPlay自动外观前提、控制中心进度操作及更新旧版的步骤。
- readme-writer离线校验为0错误、0警告，新增主题与媒体订阅声明已关联当前源码及实测记录。
- MarkdownIt以CommonMark与表格扩展生成HTML，标题、列表、加粗、链接、图标和表格解析正常，无未解析的加粗星号。
- 本次通过本地预览在Codex内置浏览器检查常规首屏、390px窄屏与主题段落，显示正常；该检查验证本地渲染效果，不等同GitHub网页实测。

## 构建25外观控制修复

- 连接信息上报当前日夜模式，控制通道就绪后补发最新选择。
- 构建24曾给实时请求增加主显示器标识，按CSeq跟踪应答，构建25已修正此处理，显示接受、拒绝或超时状态。
- 两项针对性测试通过；实际CarPlay外观切换待新包真机验证。

## 构建25外观协议修正

- 移除未经真机证实的主显示器UUID，按setNightMode参考实现发送布尔日夜参数。
- 应答无CSeq时按发送顺序匹配，同时检查二进制plist正文中的status，避免将传输成功误认为命令成功。
- 三项针对性测试通过。用户已确认构建24不能实时切换；构建25实际效果待真机验证。
- 协议核对来源：https://github.com/maaiika/Carplay/blob/master/Sources/AirPlayReceiverSession.c（仅核对消息结构，未引入该文件或源码）。

## 构建26外观控制

- 用户确认构建25收到成功应答，但地图与搜索列表均未切换。
- 核对本机Xcode CarPlaySimulator插件内CarPlaySDK的UIAppearanceUpdate与MapAppearanceUpdate消息结构，新增uiAppearanceUpdate和mapAppearanceUpdate。参数为params内uuid、appearanceMode（0浅色/1深色）、appearanceSetting（0自动）。保留旧日夜通知用于兼容。未复制或打包Apple框架。
- TypeScript编译与三项针对性测试通过，实际画面切换待真机确认。

## 构建27媒体状态修复

- 标题变化不再当作切歌，兼容QQ音乐通过标题发送歌词，保留封面、时长、进度与待处理跳转。曲目ID或应用改变时才重置曲目。
- 新封面尚未到达时保留现有封面，收到图片后再替换；忽略带旧时间戳的播放位置。
- 媒体状态与大封面分片测试通过，控制中心实际显示和拖动效果待真机确认。

## 构建28移除主题调节

- 按用户要求移除主题选择、设置持久化、Mac外观监听及CarPlay日夜/UI/地图外观通知。主窗口使用系统默认外观，旧配置的主题字段不再读取。
- README和TXT移除主题使用说明。保留此前媒体封面、歌词标题和播放进度修复。
