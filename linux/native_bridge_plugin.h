#ifndef FLUTTER_PLUGIN_NATIVE_BRIDGE_PLUGIN_H_
#define FLUTTER_PLUGIN_NATIVE_BRIDGE_PLUGIN_H_

#include <flutter_linux/flutter_linux.h>

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(NativeBridgePlugin, native_bridge_plugin, NATIVE_BRIDGE, PLUGIN, GObject)

void native_bridge_plugin_register_with_registrar(FlPluginRegistrar* registrar);

G_END_DECLS

#endif  // FLUTTER_PLUGIN_NATIVE_BRIDGE_PLUGIN_H_
