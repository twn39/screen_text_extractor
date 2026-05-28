import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_text_extractor/screen_text_extractor.dart';

void main() {
  const MethodChannel channel = MethodChannel('screen_text_extractor');
  const MethodChannel watcherChannel = MethodChannel('clipboard_watcher');
  const MethodChannel platformChannel =
      MethodChannel('flutter/platform', JSONMethodCodec());

  TestWidgetsFlutterBinding.ensureInitialized();

  final List<MethodCall> methodCalls = [];
  String? mockAccessibilityResult;
  bool shouldSimulateCopyFail = false;
  String clipboardText = '';

  setUp(() {
    methodCalls.clear();
    mockAccessibilityResult = null;
    shouldSimulateCopyFail = false;
    clipboardText = '';

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        methodCalls.add(methodCall);
        if (methodCall.method == 'isAccessAllowed') {
          return true;
        }
        if (methodCall.method == 'extractFromAccessibility') {
          if (mockAccessibilityResult != null) {
            return mockAccessibilityResult;
          }
          return null; // Return null to trigger fallback
        }
        if (methodCall.method == 'simulateCtrlCKeyPress') {
          if (shouldSimulateCopyFail) {
            throw PlatformException(code: 'ERROR', message: 'Fail');
          }
          // Simulate Ctrl+C putting text into the clipboard
          clipboardText = 'Mocked Copy Text';
          // Simulate the native platform triggering the onClipboardChanged callback
          final ByteData messageData = const StandardMethodCodec().encodeMethodCall(
            const MethodCall('onClipboardChanged'),
          );
          await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .handlePlatformMessage(
            'clipboard_watcher',
            messageData,
            (ByteData? reply) {},
          );
          return true;
        }
        return null;
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      watcherChannel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'start') {
          return null;
        }
        if (methodCall.method == 'stop') {
          return null;
        }
        return null;
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      platformChannel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'Clipboard.setData') {
          final Map? args = methodCall.arguments as Map?;
          clipboardText = args?['text'] ?? '';
          return null;
        }
        if (methodCall.method == 'Clipboard.getData') {
          return {'text': clipboardText};
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(watcherChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(platformChannel, null);
  });

  test('isAccessAllowed', () async {
    expect(await screenTextExtractor.isAccessAllowed(), isTrue);
  });

  test('extractFromScreenSelection via Accessibility channel successfully',
      () async {
    mockAccessibilityResult = 'Text from Accessibility API';

    final ExtractedData? result = await screenTextExtractor.extract(
      mode: ExtractMode.screenSelection,
    );

    expect(result?.text, equals('Text from Accessibility API'));
    expect(
      methodCalls.map((c) => c.method),
      contains('extractFromAccessibility'),
    );
    expect(
      methodCalls.map((c) => c.method),
      isNot(contains('simulateCtrlCKeyPress')),
    );
  });

  test(
      'extractFromScreenSelection fallbacks to simulateCtrlCKeyPress when Accessibility returns null',
      () async {
    mockAccessibilityResult = null;
    await Clipboard.setData(const ClipboardData(text: ''));

    final ExtractedData? result = await screenTextExtractor.extract(
      mode: ExtractMode.screenSelection,
    );

    expect(result?.text, equals('Mocked Copy Text'));

    final methods = methodCalls.map((c) => c.method).toList();
    expect(methods, contains('extractFromAccessibility'));
    expect(methods, contains('simulateCtrlCKeyPress'));
  });
}
