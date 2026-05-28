import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'extract_mode.dart';
import 'extracted_data.dart';
import 'clipboard_once_watcher.dart';

class ScreenTextExtractor {
  ScreenTextExtractor._();

  /// The shared instance of [ScreenTextExtractor].
  static final ScreenTextExtractor instance = ScreenTextExtractor._();

  final MethodChannel _channel = const MethodChannel('screen_text_extractor');

  final ClipboardOnceWatcher _clipboardOnceWatcher = ClipboardOnceWatcher();

  Future<bool> isAccessAllowed() async {
    if (!kIsWeb && Platform.isMacOS) {
      return await _channel.invokeMethod('isAccessAllowed');
    }
    return true;
  }

  Future<void> requestAccess({
    bool onlyOpenPrefPane = false,
  }) async {
    if (!kIsWeb && Platform.isMacOS) {
      final Map<String, dynamic> arguments = {
        'onlyOpenPrefPane': onlyOpenPrefPane,
      };
      await _channel.invokeMethod('requestAccess', arguments);
    }
  }

  Future<ExtractedData?> extract({
    ExtractMode mode = ExtractMode.clipboard,
  }) async {
    if (mode == ExtractMode.clipboard) {
      return await _extractFromClipboard();
    } else if (mode == ExtractMode.screenSelection) {
      return await _extractFromScreenSelection();
    } else {
      throw ArgumentError('Invalid extract mode: $mode');
    }
  }

  Future<bool> _simulateCtrlCKeyPress() async {
    return await _channel.invokeMethod('simulateCtrlCKeyPress', {});
  }

  Future<ExtractedData?> _extractFromClipboard() async {
    ClipboardData? d = await Clipboard.getData(Clipboard.kTextPlain);
    if (d == null) return null;
    return ExtractedData(text: d.text ?? '');
  }

  Future<ExtractedData?> _extractFromScreenSelection() async {
    if (Platform.isWindows || Platform.isMacOS) {
      // 1. Try Channel 1: Extract via Native Accessibility APIs
      try {
        final String? text =
            await _channel.invokeMethod('extractFromAccessibility');
        if (text != null && text.trim().isNotEmpty) {
          return ExtractedData(text: text);
        }
      } catch (e) {
        debugPrint('extractFromAccessibility failed: $e');
      }

      // 2. Try Channel 2: Fallback to keyboard simulation with clipboard backup & restore
      return await _extractWithSimulateFallback();
    } else {
      final Map<dynamic, dynamic> resultData = await _channel.invokeMethod(
        'extractFromScreenSelection',
      );

      return ExtractedData.fromJson(
        Map<String, dynamic>.from(resultData),
      );
    }
  }

  Future<ExtractedData?> _extractWithSimulateFallback() async {
    // Backup the current clipboard content
    String? originalText;
    try {
      final ClipboardData? originalData =
          await Clipboard.getData(Clipboard.kTextPlain);
      originalText = originalData?.text;
    } catch (_) {}

    Completer<ExtractedData?> completer = Completer<ExtractedData?>();

    await _clipboardOnceWatcher.watch(
      onChange: () async {
        if (completer.isCompleted) return;

        final ExtractedData? extracted = await _extractFromClipboard();
        completer.complete(extracted);

        // Restore original clipboard text after a brief delay
        Future.delayed(const Duration(milliseconds: 150), () async {
          try {
            await Clipboard.setData(ClipboardData(text: originalText ?? ''));
          } catch (_) {}
        });
      },
      onTimeout: () {
        if (completer.isCompleted) return;
        completer.complete(null);
      },
    );

    // Simulate Ctrl+C keypress to force copying selected text
    await _simulateCtrlCKeyPress();
    return completer.future;
  }
}

final screenTextExtractor = ScreenTextExtractor.instance;
