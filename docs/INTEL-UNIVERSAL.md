# MacPlay1.1.0构建29：Intel与通用版

日期：2026年10月1日。

Intel支持基础来自[drewpall的PR#1](https://github.com/Roylyl/MacPlay/pull/1)，该PR已合并。构建29补齐运行时架构与通用打包流程，应用版本仍为1.1.0。

## 安装包

- `MacPlay-1.1.0-universal.dmg`：Apple Silicon与Intel通用，macOS14及以上。
- `MacPlay-1.1.0-x86_64.dmg`：Intel，macOS14及以上。

两者使用相同设置目录和认证准备逻辑。通用版自动使用本机架构，Intel不需要Rosetta。源码、签名与安装条件见[项目README](../README.md)，用户操作见[发行版使用教程](发行版使用教程.md)。

## 构建改动

分别以arm64与x86_64目标编译Swift主程序、Objective-C蓝牙桥接、Rust连接后端、加密与视频N-API模块。通用版使用lipo合并每个原生组件，而不是向swiftc重复传入目标参数。

打包时获取与构建环境Node版本一致的官方macOS运行时，并按目标架构选择或合并，避免把本机ARM版Node打入Intel安装包。当前构建使用Node24.19.0。

GStreamer1.28.7已有公共双架构库，原有定制applemedia插件仅包含ARM架构。本次保留原有ARM插件，加入官方同版本Intel插件及其Vulkan/MoltenVK依赖；Intel插件使用官方实现，没有移植ARM定制的低延迟补丁。打包时检查每个可执行组件与媒体库是否包含目标架构，不满足条件则停止。

## 验证范围

- Swift、蓝牙桥接、Rust后端、加密与视频模块的两种架构编译完成，TypeScript编译通过。
- 通用应用的ARM与Intel模式均成功运行Node24.19.0、加载加密及视频模块，视频窗口接口存在。
- 两种模式均成功加载并识别VideoToolbox硬件解码器vtdec_hw。
- 通用应用的递归签名检查通过，采用本地签名，未经过Apple公证。

Intel模式运行检查在Apple Silicon上通过Rosetta完成，不等同于Intel实体Mac验证。本次没有替用户切换连接，也未实测Intel实体Mac与iPhone的有线/无线连接、实时音视频及播放控制。已识别硬件解码器不等于完成真实视频解码测试。
