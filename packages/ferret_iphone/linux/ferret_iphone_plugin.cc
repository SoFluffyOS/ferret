#include "include/ferret_iphone/ferret_iphone_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

#include <cstring>

#include "messages.g.h"
#include "ferret_iphone_plugin_private.h"

#define FERRET_IPHONE_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), ferret_iphone_plugin_get_type(), \
                              FerretIphonePlugin))

struct _FerretIphonePlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(FerretIphonePlugin, ferret_iphone_plugin, g_object_get_type())

gchar* ferret_iphone_plugin_get_platform_version() {
  struct utsname uname_data = {};
  uname(&uname_data);
  return g_strdup_printf("Linux %s", uname_data.version);
}

static FerretIphoneFerretIphonePluginApiGetPlatformVersionResponse *handle_get_platform_version(gpointer user_data) {
  // The plugin instance is unused in this simple example, but more complex
  // plugins may have plugin state to access here.
  // FerretIphonePlugin* self = FERRET_IPHONE_PLUGIN(user_data);

  g_autofree gchar *version = ferret_iphone_plugin_get_platform_version();
  return ferret_iphone_ferret_iphone_plugin_api_get_platform_version_response_new(version);
}

static void ferret_iphone_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(ferret_iphone_plugin_parent_class)->dispose(object);
}

static void ferret_iphone_plugin_class_init(FerretIphonePluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = ferret_iphone_plugin_dispose;
}

static void ferret_iphone_plugin_init(FerretIphonePlugin* self) {}

void ferret_iphone_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  FerretIphonePlugin* plugin = FERRET_IPHONE_PLUGIN(
      g_object_new(ferret_iphone_plugin_get_type(), nullptr));

  static FerretIphoneFerretIphonePluginApiVTable api_vtable = {
    .get_platform_version = handle_get_platform_version
  };
  ferret_iphone_ferret_iphone_plugin_api_set_method_handlers(
    fl_plugin_registrar_get_messenger(registrar), nullptr,
    &api_vtable, g_object_ref(plugin), g_object_unref);

  g_object_unref(plugin);
}
