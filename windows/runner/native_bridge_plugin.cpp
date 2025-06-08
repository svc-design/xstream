#include "native_bridge_plugin.h"
#include "utils.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <fstream>
#include <memory>
#include <sstream>
#include <string>

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
    std::string path = get_string("xrayConfigPath");
    std::string content = get_string("xrayConfigContent");
    std::ofstream file(path, std::ios::out | std::ios::trunc);
    if (!file) {
      result->Error("WRITE_ERROR", "Failed to open file");
      Log("error", "Failed to open file: " + path);
      return;
    }
    file << content;
    file.close();
    Log("info", "Wrote config file: " + path);
    result->Success(flutter::EncodableValue(true));
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
    std::string cmd;
    if (method == "startNodeService") {
      cmd = "sc start " + service;
    } else if (method == "stopNodeService") {
      cmd = "sc stop " + service;
    } else {
      cmd = "sc query " + service + " | find \"RUNNING\"";
    }
    int ret = system(cmd.c_str());
    bool success = (ret == 0);
    if (method == "checkNodeStatus") {
      result->Success(flutter::EncodableValue(success));
    } else {
      result->Success(flutter::EncodableValue(success ? "success" : "failed"));
    }
    Log("info", "Executed: " + cmd);
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
      result->Success(flutter::EncodableValue("\xE2\x9C\x85 Xray \xE5\x88\x9D\xE5\xA7\x8B\xE5\x8C\x96\xE5\xAE\x8C\xE6\x88\x90"));
    } else if (action == "resetXrayAndConfig") {
      result->Success(flutter::EncodableValue("\xE2\x9C\x85 \xE5\xB7\xB2\xE6\xB8\x85\xE9\x99\xA4\xE9\x85\x8D\xE7\xBD\xAE\xE4\xB8\x8E\xE5\xAE\x89\xE8\xA3\x85\xE6\x96\x87\xE4\xBB\xB6"));
    } else {
      result->Error("UNKNOWN_ACTION", "Unsupported action");
    }
    return;
  }

  result->NotImplemented();
}

