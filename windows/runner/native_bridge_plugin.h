#ifndef RUNNER_NATIVE_BRIDGE_PLUGIN_H_
#define RUNNER_NATIVE_BRIDGE_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <string>

class NativeBridgePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(
      flutter::PluginRegistrarWindows *registrar);

  NativeBridgePlugin();
  virtual ~NativeBridgePlugin();

  // Disallow copy and assign.
  NativeBridgePlugin(const NativeBridgePlugin&) = delete;
  NativeBridgePlugin& operator=(const NativeBridgePlugin&) = delete;

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void Log(const std::string &level, const std::string &message);

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> logger_channel_;
};

#endif  // RUNNER_NATIVE_BRIDGE_PLUGIN_H_
