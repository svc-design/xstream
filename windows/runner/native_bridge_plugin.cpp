#include "native_bridge_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <string>
#include <variant>
#include <iostream>
#include "utils.h"

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

    const char* res = WriteConfigFiles(
        get_string("xrayConfigPath").c_str(),
        get_string("xrayConfigContent").c_str(),
        get_string("servicePath").c_str(),
        get_string("serviceContent").c_str(),
        get_string("vpnNodesConfigPath").c_str(),
        get_string("vpnNodesConfigContent").c_str(),
        get_string("password").c_str());
    if (g_debugMode) {
      std::cout << "writeConfigFiles -> " << res << std::endl;
    }

    if (strncmp(res, "error:", 6) == 0) {
      result->Error("WRITE_ERROR", res + 6);
    } else {
      result->Success(flutter::EncodableValue(res));
    }
    FreeCString(const_cast<char*>(res));
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

    const std::string service = get_string("serviceName");
    if (method == "startNodeService") {
      const char* res = StartNodeService(service.c_str());
      if (g_debugMode) {
        std::cout << method << " -> " << res << std::endl;
      }
      if (strncmp(res, "error:", 6) == 0) {
        result->Error("EXEC_FAILED", res + 6);
      } else {
        result->Success(flutter::EncodableValue(res));
      }
      FreeCString(const_cast<char*>(res));
    } else if (method == "stopNodeService") {
      const char* res = StopNodeService(service.c_str());
      if (g_debugMode) {
        std::cout << method << " -> " << res << std::endl;
      }
      if (strncmp(res, "error:", 6) == 0) {
        result->Error("EXEC_FAILED", res + 6);
      } else {
        result->Success(flutter::EncodableValue(res));
      }
      FreeCString(const_cast<char*>(res));
    } else {
      int state = CheckNodeStatus(service.c_str());
      if (state >= 0) {
        result->Success(flutter::EncodableValue(state == 1));
      } else {
        result->Error("EXEC_FAILED", "check failed");
      }
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

    const std::string action = get_string("action");
    if (action == "initXray") {
      const char* res = InitXray();
      if (g_debugMode) {
        std::cout << "initXray -> " << res << std::endl;
      }
      if (strncmp(res, "error:", 6) == 0) {
        result->Error("EXEC_FAILED", res + 6);
      } else {
        result->Success(flutter::EncodableValue(res));
      }
      FreeCString(const_cast<char*>(res));
    } else if (action == "resetXrayAndConfig") {
      const char* res = ResetXrayAndConfig(get_string("password").c_str());
      if (g_debugMode) {
        std::cout << "resetXrayAndConfig -> " << res << std::endl;
      }
      if (strncmp(res, "error:", 6) == 0) {
        result->Error("EXEC_FAILED", res + 6);
      } else {
        result->Success(flutter::EncodableValue(res));
      }
      FreeCString(const_cast<char*>(res));
    } else {
      result->Error("UNKNOWN_ACTION", "Unsupported action");
    }
    return;
  }

  result->NotImplemented();
#endif
}
