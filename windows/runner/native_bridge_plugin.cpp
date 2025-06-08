#include "native_bridge_plugin.h"
#include "utils.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <fstream>
#include <memory>
#include <sstream>
#include <string>
#include "go_logic.h"

NativeBridgePlugin::NativeBridgePlugin() {}

NativeBridgePlugin::~NativeBridgePlugin() {}

void NativeBridgePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), "com.xstream/native",
      &flutter::StandardMethodCodec::GetInstance());

  auto logger_channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), "com.xstream/logger",
      &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<NativeBridgePlugin>();
  plugin->logger_channel_ = std::move(logger_channel);

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

void NativeBridgePlugin::Log(const std::string &level, const std::string &message) {
  if (!logger_channel_)
    return;
  std::stringstream ss;
  ss << "[" << level << "] " << message;
  logger_channel_->InvokeMethod(
      "log",
      std::make_unique<flutter::EncodableValue>(ss.str()));
}

void NativeBridgePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const std::string &method = call.method_name();

  if (method == "writeConfigFiles") {
    const auto *args = std::get_if<flutter::EncodableMap>(call.arguments());
    if (!args) {
      result->Error("INVALID_ARGS", "Arguments not a map");
      return;
    }
    auto get_string = [&](const std::string &key) -> std::string {
      auto it = args->find(flutter::EncodableValue(key));
      if (it != args->end() && it->second.IsString())
        return std::get<std::string>(it->second);
      return "";
    };

    std::string xray_path = get_string("xrayConfigPath");
    std::string xray_content = get_string("xrayConfigContent");
    std::string plist_path = get_string("plistPath");
    std::string plist_content = get_string("plistContent");
    std::string vpn_path = get_string("vpnNodesConfigPath");
    std::string vpn_content = get_string("vpnNodesConfigContent");

    bool ok = true;
    if (WriteConfigFile(xray_path.c_str(), xray_content.c_str()) != 0) {
      Log("error", "Failed to write: " + xray_path);
      ok = false;
    }
    if (WriteConfigFile(plist_path.c_str(), plist_content.c_str()) != 0) {
      Log("error", "Failed to write: " + plist_path);
      ok = false;
    }
    if (UpdateVpnNodesConfig(vpn_path.c_str(), vpn_content.c_str()) != 0) {
      Log("error", "Failed to update: " + vpn_path);
      ok = false;
    }

    if (ok) {
      result->Success(flutter::EncodableValue("Configuration files written successfully"));
    } else {
      result->Error("WRITE_ERROR", "Failed to write one or more files");
    }
    return;
  } else if (method == "startNodeService" || method == "stopNodeService" ||
             method == "checkNodeStatus") {
    const auto *args = std::get_if<flutter::EncodableMap>(call.arguments());
    if (!args) {
      result->Error("INVALID_ARGS", "Arguments not a map");
      return;
    }
    std::string service;
    auto it = args->find(flutter::EncodableValue("plistName"));
    if (it != args->end() && it->second.IsString()) {
      service = std::get<std::string>(it->second);
    }

    int ret = -1;
    if (method == "startNodeService") {
      ret = StartNodeService(service.c_str());
    } else if (method == "stopNodeService") {
      ret = StopNodeService(service.c_str());
    } else {
      ret = CheckNodeStatus(service.c_str());
    }

    if (method == "checkNodeStatus") {
      result->Success(flutter::EncodableValue(ret == 1));
    } else {
      result->Success(flutter::EncodableValue(ret == 0 ? "success" : "failed"));
    }
    return;
  } else if (method == "performAction") {
    const auto *args = std::get_if<flutter::EncodableMap>(call.arguments());
    std::string action;
    if (args) {
      auto it = args->find(flutter::EncodableValue("action"));
      if (it != args->end() && it->second.IsString())
        action = std::get<std::string>(it->second);
    }
    if (action == "initXray") {
      int ret = InitXray();
      if (ret == 0) {
        result->Success(flutter::EncodableValue("\xE2\x9C\x85 Xray \xE5\x88\x9D\xE5\xA7\x8B\xE5\x8C\x96\xE5\xAE\x8C\xE6\x88\x90"));
      } else {
        result->Error("EXEC_FAILED", "InitXray failed");
      }
    } else if (action == "resetXrayAndConfig") {
      std::string password;
      if (args) {
        auto pit = args->find(flutter::EncodableValue("password"));
        if (pit != args->end() && pit->second.IsString()) {
          password = std::get<std::string>(pit->second);
        }
      }
      int ret = ResetXrayAndConfig(password.c_str());
      if (ret == 0) {
        result->Success(flutter::EncodableValue("\xE2\x9C\x85 \xE5\xB7\xB2\xE6\xB8\x85\xE9\x99\xA4\xE9\x85\x8D\xE7\xBD\xAE\xE4\xB8\x8E\xE5\xAE\x89\xE8\xA3\x85\xE6\x96\x87\xE4\xBB\xB6"));
      } else {
        result->Error("EXEC_FAILED", "Reset failed");
      }
    } else {
      result->Error("UNKNOWN_ACTION", "Unsupported action");
    }
    return;
  }

  result->NotImplemented();
}

