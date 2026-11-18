#include "include/ferret_power/ferret_power_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

#include <cstring>

#include "messages.g.h"
#include "ferret_power_plugin_private.h"

#define FERRET_POWER_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), ferret_power_plugin_get_type(), \
                              FerretPowerPlugin))

struct _FerretPowerPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(FerretPowerPlugin, ferret_power_plugin, g_object_get_type())

gchar* ferret_power_plugin_get_platform_version() {
  struct utsname uname_data = {};
  uname(&uname_data);
  return g_strdup_printf("Linux %s", uname_data.version);
}

static FerretPowerFerretPowerPluginApiGetPlatformVersionResponse *handle_get_platform_version(gpointer user_data) {
  // The plugin instance is unused in this simple example, but more complex
  // plugins may have plugin state to access here.
  // FerretPowerPlugin* self = FERRET_POWER_PLUGIN(user_data);

  g_autofree gchar *version = ferret_power_plugin_get_platform_version();
  return ferret_power_ferret_power_plugin_api_get_platform_version_response_new(version);
}

static void ferret_power_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(ferret_power_plugin_parent_class)->dispose(object);
}

static void ferret_power_plugin_class_init(FerretPowerPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = ferret_power_plugin_dispose;
}

static void ferret_power_plugin_init(FerretPowerPlugin* self) {}

void ferret_power_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  FerretPowerPlugin* plugin = FERRET_POWER_PLUGIN(
      g_object_new(ferret_power_plugin_get_type(), nullptr));

  static FerretPowerFerretPowerPluginApiVTable api_vtable = {
    .get_platform_version = handle_get_platform_version
  };
  ferret_power_ferret_power_plugin_api_set_method_handlers(
    fl_plugin_registrar_get_messenger(registrar), nullptr,
    &api_vtable, g_object_ref(plugin), g_object_unref);

  g_object_unref(plugin);
}
