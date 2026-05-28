//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <clipboard_watcher/clipboard_watcher_plugin.h>
#include <hotkey_manager_windows/hotkey_manager_windows_plugin_c_api.h>
#include <screen_text_extractor/screen_text_extractor_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  ClipboardWatcherPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("ClipboardWatcherPlugin"));
  HotkeyManagerWindowsPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("HotkeyManagerWindowsPluginCApi"));
  ScreenTextExtractorPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("ScreenTextExtractorPlugin"));
}
