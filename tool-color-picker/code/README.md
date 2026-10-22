# 取色器（macOS）

一个本地运行的原生 macOS 屏幕取色小工具。界面借鉴 PicPick 的取色、颜色预览和快速复制工作流；取色功能使用 macOS 原生 `NSColorSampler`，支持将指针移动到连接在同一台 Mac 上的任意显示器取色。

## 功能

- 固定尺寸紧凑窗口，跨显示器拾取屏幕像素，使用系统放大镜精确定位
- HEX / RGB 格式切换，颜色代码可编辑
- 一键复制当前格式到系统剪贴板
- 显示当前颜色预览和最近拾取的 8 种颜色
- 本地运行，不上传屏幕图像或颜色数据
- 彩色圆环与吸管组合的 macOS 应用图标

## 构建与运行

需要 macOS 13+、Swift 5.9+（Xcode 命令行工具）。在本目录执行：

```sh
./build.sh
open dist/PicPick.app
```

脚本同时生成可双击安装的 `dist/PicPick-1.0.0.pkg`，默认安装到 `/Applications`。安装包目前未签名；首次打开时若出现 Gatekeeper 提示，可在 Finder 中对应用使用“右键 > 打开”。

也可以直接开发运行：

```sh
swift run
```

初次使用时点击底部“屏幕取色”，系统取色器会接管指针；在任一屏幕点选颜色或按 Esc 取消。之后颜色显示在面板中，可编辑 HEX 并应用，或者切换 RGB 后复制。

## 参考与实现选择

- [PicPick 官方功能说明](https://picpick.app/en/help/)：参考屏幕取色、颜色预览及快速复制等功能方向。
- [Pika（GitHub）](https://github.com/superhighfives/pika)：开源 macOS 原生取色器，作为原生应用交互与平台能力的参考。本项目采用独立实现，未复制其源码。
- [Apple NSColorSampler](https://developer.apple.com/documentation/appkit/nscolorsampler)：系统屏幕取色 API，处理系统级指针放大镜和多显示器屏幕拾色。
