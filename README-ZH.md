# screen_text_extractor

一个专为 Flutter 桌面端应用（**macOS, Windows, Linux**）打造的强大屏幕文本提取插件。支持基于系统辅助功能（Accessibility）的零剪贴板污染全局划词取词，以及带剪贴板历史自动恢复的安全复制模拟双通道兜底机制。

---

[English](./README.md) | [简体中文](./README-ZH.md)

---

## 🚀 功能特性与双通道取词管道

与简单的按键模拟脚本不同，`screen_text_extractor` 在各平台实现了一套专业的**双通道屏幕取词管道**，提供卓越的原生体验：

### 1. 第一通道：系统辅助功能 API（零剪贴板污染）
* **macOS**：利用 ApplicationServices 的 `AXUIElement` 框架检查当前焦点的 UI 节点树，直接读取选中的 `kAXSelectedTextAttribute` 属性。
* **Windows**：利用 Microsoft UI Automation (UIA) COM 接口，读取 `IUIAutomationTextPattern` 活跃选区中的文本。
* *此原生过程完全不修改、不污染系统剪贴板。*

### 2. 第二通道：按键模拟复制兜底（带剪贴板自动恢复）
* 如果目标应用没有完整实现系统可访问性协议（如某些自定义 Canvas 或游戏等），插件会自动回退到模拟按下 `Ctrl+C` (或 `Cmd+C`)。
* 在读取到剪贴板的变化内容后，会立刻异步调度任务**恢复用户原有的剪贴板内容**，保证用户原有的复制历史记录不丢失。

### 3. 原生 Linux 支持
* 直接读取 X11/GTK 的主选择区（`GDK_SELECTION_PRIMARY`）。在 Linux 系统中，鼠标划选的文字会自动进入该选区中，因此也是原生实现，完全不污染普通剪贴板。

---

## 💻 平台支持

| Linux | macOS | Windows |
| :---: | :---: | :-----: |
|   ✔️ 完美支持   |   ✔️ 完美支持   |    ✔️ 完美支持    |

---

## 🛠️ 快速开始

### 安装

将此添加到你的软件包的 `pubspec.yaml` 文件中：

```yaml
dependencies:
  screen_text_extractor:
    git:
      url: https://github.com/twn39/screen_text_extractor.git
```

### 用法示例

```dart
import 'package:screen_text_extractor/screen_text_extractor.dart';

// 1. 从系统剪贴板中提取纯文本
ExtractedData? data = await screenTextExtractor.extract(
  mode: ExtractMode.clipboard,
);

// 2. 从屏幕选区中划词提取文本（双通道）
ExtractedData? data = await screenTextExtractor.extract(
  mode: ExtractMode.screenSelection,
);

print(data?.text);
```

> 💡 **macOS 注意事项**：使用划词提取功能需要系统授予**辅助功能权限（Accessibility）**。您可以使用以下内置的帮助方法在应用中轻松检测并申请该权限：

```dart
// 检查 macOS 辅助功能是否已授权
bool allowed = await screenTextExtractor.isAccessAllowed();

if (!allowed) {
  // 申请访问（会自动打开 macOS 辅助功能系统设置面板）
  await screenTextExtractor.requestAccess();
}
```

---

## 📖 API 参考

### 方法

| 方法 | 返回类型 | 描述 | Linux | macOS | Windows |
| :--- | :--- | :--- | :---: | :---: | :---: |
| `isAccessAllowed()` | `Future<bool>` | 仅限 macOS，检查辅助功能权限是否通过。 | ➖ | ✔️ | ➖ |
| `requestAccess(...)` | `Future<void>` | 仅限 macOS，触发授权弹窗或直接打开隐私设置面板。 | ➖ | ✔️ | ➖ |
| `extract(...)` | `Future<ExtractedData?>` | 通过剪贴板（`clipboard`）或屏幕选区（`screenSelection`）提取文本。 | ✔️ | ✔️ | ✔️ |

### 数据模型

#### `ExtractedData`
* `text`: 从屏幕选区或剪贴板中成功提取出的文本内容。

---

## 📄 许可证

本项目采用 [MIT 许可证](./LICENSE) 开源。