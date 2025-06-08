#include "native_bridge_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <string>
#include <variant>

#ifdef USE_GO_LOGIC
#include "go_logic.h"
#endif

NativeBridgePlugin::NativeBridgePlugin() = default;
NativeBridgePlugin::~NativeBridgePlugin() = default;

void NativeBridgePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), "com.xstream/native",
      &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<NativeBridgePlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

void NativeBridgePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const std::string& method = call.method_name();

#ifndef USE_GO_LOGIC
  result->Error("UNAVAILABLE", "Native Go logic not available in this build");
  return;
#else
  if (method == "writeConfigFiles") {
    const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
    if (!args) {
      result->Error("INVALID_ARGS", "Arguments not a map");
      return;
    }
    auto get_string = [&](const std::string& key) -> std::string {
      auto it = args->find(flutter::EncodableValue(key));
      if (it != args->end() && std::holds_alternative<std::string>(it->second)) {
        return std::get<std::string>(it->second);
      }
      return "";
    };

    int ret = WriteConfigFiles(
        get_string("xrayConfigPath").c_str(),
        get_string("xrayConfigContent").c_str(),
        get_string("plistPath").c_str(),
        get_string("plistContent").c_str(),
        get_string("vpnNodesConfigPath").c_str(),
        get_string("vpnNodesConfigContent").c_str());

    if (ret == 0) {
      result->Success(flutter::EncodableValue("Configuration files written successfully"));
    } else {
      result->Error("WRITE_ERROR", "Failed to write configuration files");
    }
    return;
  }

  if (method == "startNodeService" || method == "stopNodeService" || method == "checkNodeStatus") {
    const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
    if (!args) {
      result->Error("INVALID_ARGS", "Arguments not a map");
      return;
    }
    auto get_string = [&](const std::string& key) -> std::string {
      auto it = args->find(flutter::EncodableValue(key));
      if (it != args->end() && std::holds_alternative<std::string>(it->second)) {
        return std::get<std::string>(it->second);
      }
      return "";
    };

    int ret = ControlNodeService(method.c_str(), get_string("plistName").c_str());

    if (method == "checkNodeStatus") {
      result->Success(flutter::EncodableValue(ret == 1));
    } else {
      result->Success(flutter::EncodableValue(ret == 0 ? "success" : "failed"));
    }
    return;
  }

  if (method == "performAction") {
    const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
    if (!args) {
      result->Error("INVALID_ARGS", "Arguments not a map");
      return;
    }
    auto get_string = [&](const std::string& key) -> std::string {
      auto it = args->find(flutter::EncodableValue(key));
      if (it != args->end() && std::holds_alternative<std::string>(it->second)) {
        return std::get<std::string>(it->second);
      }
      return "";
    };

    int ret = PerformAction(get_string("action").c_str(), get_string("password").c_str());

    if (ret == 0) {
      result->Success(flutter::EncodableValue("success"));
    } else if (ret == 1) {
      result->Error("EXEC_FAILED", "Action failed");
    } else {
      result->Error("UNKNOWN_ACTION", "Unsupported action");
    }
    return;
  }

  result->NotImplemented();
#endif
}
