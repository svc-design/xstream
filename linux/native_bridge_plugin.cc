#include "native_bridge_plugin.h"
#include "go/native_bridge.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

#include <cstring>
#include <string>
#include <cstdio>
#include <algorithm>

#define NATIVE_BRIDGE_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), native_bridge_plugin_get_type(), NativeBridgePlugin))

struct _NativeBridgePlugin {
  GObject parent_instance;
  FlMethodChannel* logger_channel;
};

G_DEFINE_TYPE(NativeBridgePlugin, native_bridge_plugin, g_object_get_type())

static void native_bridge_plugin_dispose(GObject* object) {
  NativeBridgePlugin* self = NATIVE_BRIDGE_PLUGIN(object);
  g_clear_object(&self->logger_channel);
  G_OBJECT_CLASS(native_bridge_plugin_parent_class)->dispose(object);
}

static void native_bridge_plugin_class_init(NativeBridgePluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = native_bridge_plugin_dispose;
}

static void native_bridge_plugin_init(NativeBridgePlugin* self) {}


static std::string current_timestamp() {
  g_autoptr(GDateTime) now = g_date_time_new_now_local();
  gchar* ts = g_date_time_format(now, "%Y-%m-%d %H:%M:%S");
  std::string out(ts);
  g_free(ts);
  return out;
}

static void log_to_flutter(NativeBridgePlugin* self, const std::string& level,
                           const std::string& message) {
  if (!self->logger_channel) return;
  std::string lvl = level;
  std::transform(lvl.begin(), lvl.end(), lvl.begin(), ::toupper);
  std::string full = "[" + lvl + "] " + current_timestamp() + ": " + message;
  g_autoptr(FlValue) value = fl_value_new_string(full.c_str());
  fl_method_channel_invoke_method(self->logger_channel, "log", value, nullptr,
                                  nullptr, nullptr);
}

static void handle_method_call(NativeBridgePlugin* self, FlMethodCall* method_call) {
  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);

  g_autoptr(FlMethodResponse) response = nullptr;

  if (strcmp(method, "writeConfigFiles") == 0) {
    const gchar* xray_path = fl_value_get_string(fl_value_lookup_string(args, "xrayConfigPath"));
    const gchar* xray_content = fl_value_get_string(fl_value_lookup_string(args, "xrayConfigContent"));
    const gchar* plist_path = fl_value_get_string(fl_value_lookup_string(args, "plistPath"));
    const gchar* plist_content = fl_value_get_string(fl_value_lookup_string(args, "plistContent"));
    const gchar* vpn_path = fl_value_get_string(fl_value_lookup_string(args, "vpnNodesConfigPath"));
    const gchar* vpn_content = fl_value_get_string(fl_value_lookup_string(args, "vpnNodesConfigContent"));
    const gchar* password = fl_value_get_string(fl_value_lookup_string(args, "password"));

    if (xray_path && xray_content && plist_path && plist_content && vpn_path && vpn_content && password) {
      const char* res = WriteConfigFiles(xray_path, xray_content, plist_path, plist_content, vpn_path, vpn_content, password);
      if (g_str_has_prefix(res, "error:")) {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new("WRITE_ERROR", res + 6, nullptr));
        log_to_flutter(self, "error", res + 6);
      } else {
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_string(res)));
        log_to_flutter(self, "info", "Wrote configuration");
      }
      FreeCString(res);
    } else {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new("INVALID_ARGS", "Missing arguments", nullptr));
    }
  } else if (strcmp(method, "startNodeService") == 0 ||
             strcmp(method, "stopNodeService") == 0 ||
             strcmp(method, "checkNodeStatus") == 0) {
    const gchar* service = fl_value_get_string(fl_value_lookup_string(args, "plistName"));
    if (!service) {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new("INVALID_ARGS", "Missing plistName", nullptr));
    } else {
      if (strcmp(method, "startNodeService") == 0) {
        const char* res = StartNodeService(service);
        if (g_str_has_prefix(res, "error:")) {
          response = FL_METHOD_RESPONSE(fl_method_error_response_new("EXEC_FAILED", res + 6, nullptr));
          log_to_flutter(self, "error", res + 6);
        } else {
          response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_string(res)));
          log_to_flutter(self, "info", "Service started");
        }
        FreeCString(res);
      } else if (strcmp(method, "stopNodeService") == 0) {
        const char* res = StopNodeService(service);
        if (g_str_has_prefix(res, "error:")) {
          response = FL_METHOD_RESPONSE(fl_method_error_response_new("EXEC_FAILED", res + 6, nullptr));
          log_to_flutter(self, "error", res + 6);
        } else {
          response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_string(res)));
          log_to_flutter(self, "info", "Service stopped");
        }
        FreeCString(res);
      } else {
        int state = CheckNodeStatus(service);
        if (state >= 0) {
          response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(state == 1)));
        } else {
          response = FL_METHOD_RESPONSE(fl_method_error_response_new("EXEC_FAILED", "check failed", nullptr));
        }
      }
    }
  } else if (strcmp(method, "performAction") == 0) {
    const gchar* action = fl_value_get_string(fl_value_lookup_string(args, "action"));
    if (!action) {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new("INVALID_ARGS", "Missing action", nullptr));
    } else if (strcmp(action, "initXray") == 0) {
      const char* res = InitXray();
      if (g_str_has_prefix(res, "error:")) {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new("EXEC_FAILED", res + 6, nullptr));
        log_to_flutter(self, "error", res + 6);
      } else {
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_string(res)));
        log_to_flutter(self, "info", "Xray initialized");
      }
      FreeCString(res);
    } else if (strcmp(action, "resetXrayAndConfig") == 0) {
      const gchar* password = fl_value_get_string(fl_value_lookup_string(args, "password"));
      if (!password) {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new("MISSING_PASSWORD", "缺少密码", nullptr));
      } else {
        const char* res = ResetXrayAndConfig(password);
        if (g_str_has_prefix(res, "error:")) {
          response = FL_METHOD_RESPONSE(fl_method_error_response_new("EXEC_FAILED", res + 6, nullptr));
          log_to_flutter(self, "error", res + 6);
        } else {
          response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_string(res)));
          log_to_flutter(self, "info", "Reset complete");
        }
        FreeCString(res);
      }
    } else {
      std::string msg = "Unknown action: ";
      msg += action;
      response = FL_METHOD_RESPONSE(fl_method_error_response_new("UNKNOWN_ACTION", msg.c_str(), nullptr));
    }
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* call, gpointer user_data) {
  handle_method_call(NATIVE_BRIDGE_PLUGIN(user_data), call);
}

void native_bridge_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  NativeBridgePlugin* plugin = NATIVE_BRIDGE_PLUGIN(g_object_new(native_bridge_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();

  plugin->logger_channel = fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar), "com.xstream/logger", FL_METHOD_CODEC(codec));
  g_object_ref(plugin->logger_channel);

  g_autoptr(FlMethodChannel) channel = fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar), "com.xstream/native", FL_METHOD_CODEC(codec));

  fl_method_channel_set_method_call_handler(channel, method_call_cb, g_object_ref(plugin), g_object_unref);

  g_object_unref(plugin);
}


