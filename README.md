<h1 align="center">screen_text_extractor</h1>

<p align="center">
  <a href="./README.md">English</a> | <a href="./README-ZH.md">简体中文</a>
</p>

---

A powerful, high-performance Flutter plugin for desktop applications (**macOS, Windows, Linux**) to extract text from the screen. It features native accessibility-based selection grabbing (with zero clipboard pollution) and a robust copy-simulation fallback with automatic clipboard restoration.

---

## 🚀 Features & Dual-Channel Pipeline

Unlike naive keypress-simulation scripts, `screen_text_extractor` implements a professional **dual-channel extraction pipeline** to provide a seamless native experience on all platforms:

### 1. Channel 1: Native Accessibility APIs (Zero Clipboard Pollution)
* **macOS**: Utilizes the ApplicationServices `AXUIElement` framework to inspect the focused UI tree and read selected text parameters directly.
* **Windows**: Utilizes Microsoft UI Automation (UIA) COM APIs to read the `IUIAutomationTextPattern` selection range.
* *This native process reads highlighted text without altering or modifying the system clipboard at all.*

### 2. Channel 2: Copy-Simulation Fallback (With Clipboard Restore)
* If an application does not expose its selection to OS Accessibility trees, the plugin falls back to simulating a `Ctrl+C` (or `Cmd+C`) keypress.
* It reads the temporary clipboard change, and immediately schedules a delayed task to **restore the user's original clipboard content**, ensuring no text history is lost.

### 3. Native Linux Support
* Directly reads from X11/GTK's `GDK_SELECTION_PRIMARY` (Primary Selection buffer), which natively retrieves highlighted text without polluting the system clipboard.

---

## 💻 Platform Support

| Linux | macOS | Windows |
| :---: | :---: | :-----: |
|   ✔️ Fully Supported   |   ✔️ Fully Supported   |    ✔️ Fully Supported    |

---

## 🛠️ Quick Start

### Installation

Add `screen_text_extractor` to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  screen_text_extractor:
    git:
      url: https://github.com/twn39/screen_text_extractor.git
```

### Usage Example

```dart
import 'package:screen_text_extractor/screen_text_extractor.dart';

// 1. Extract plain text from clipboard
ExtractedData? data = await screenTextExtractor.extract(
  mode: ExtractMode.clipboard,
);

// 2. Extract highlighted text from screen selection (Dual-Channel)
ExtractedData? data = await screenTextExtractor.extract(
  mode: ExtractMode.screenSelection,
);

print(data?.text);
```

> 💡 **Note on macOS**: Grabbing screen selection text requires **Accessibility permissions** from the OS. Use the built-in helper methods below to easily check and request access in your app.

```dart
// Check macOS accessibility trust
bool allowed = await screenTextExtractor.isAccessAllowed();

if (!allowed) {
  // Request access (automatically opens macOS System Settings Pane)
  await screenTextExtractor.requestAccess();
}
```

---

## 📖 API Reference

### Methods

| Method | Return Type | Description | Linux | macOS | Windows |
| :--- | :--- | :--- | :---: | :---: | :---: |
| `isAccessAllowed()` | `Future<bool>` | Checks if macOS Accessibility permissions are trusted. | ➖ | ✔️ | ➖ |
| `requestAccess(...)` | `Future<void>` | Prompts accessibility request dialog or opens System Preference Pane. | ➖ | ✔️ | ➖ |
| `extract(...)` | `Future<ExtractedData?>` | Extracts text using `ExtractMode.clipboard` or `ExtractMode.screenSelection`. | ✔️ | ✔️ | ✔️ |

### Data Models

#### `ExtractedData`
* `text`: The string content retrieved from the screen selection or clipboard.

---

## 📄 License

This project is licensed under the [MIT License](./LICENSE).