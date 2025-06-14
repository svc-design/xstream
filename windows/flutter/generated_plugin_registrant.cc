//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"
#include "../runner/native_bridge_plugin.h"

#include <url_launcher_windows/url_launcher_windows.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  UrlLauncherWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("UrlLauncherWindows"));

  NativeBridgePlugin::RegisterWithRegistrar(
      registry->GetRegistrarForPlugin("NativeBridgePlugin"));
}
