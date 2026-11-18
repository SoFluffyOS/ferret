#include "include/ferret_remote_input/ferret_remote_input_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

#include <cstring>

#include "messages.g.h"
#include "ferret_remote_input_plugin_private.h"

#define FERRET_REMOTE_INPUT_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), ferret_remote_input_plugin_get_type(), \
                              FerretRemoteInputPlugin))

struct _FerretRemoteInputPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(FerretRemoteInputPlugin, ferret_remote_input_plugin, g_object_get_type())

gchar* ferret_remote_input_plugin_get_platform_version() {
  struct utsname uname_data = {};
  uname(&uname_data);
  return g_strdup_printf("Linux %s", uname_data.version);
}

static FerretRemoteInputFerretRemoteInputPluginApiGetPlatformVersionResponse *handle_get_platform_version(gpointer user_data) {
  // The plugin instance is unused in this simple example, but more complex
  // plugins may have plugin state to access here.
  // FerretRemoteInputPlugin* self = FERRET_REMOTE_INPUT_PLUGIN(user_data);

  g_autofree gchar *version = ferret_remote_input_plugin_get_platform_version();
  return ferret_remote_input_ferret_remote_input_plugin_api_get_platform_version_response_new(version);
}

static void ferret_remote_input_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(ferret_remote_input_plugin_parent_class)->dispose(object);
}

static void ferret_remote_input_plugin_class_init(FerretRemoteInputPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = ferret_remote_input_plugin_dispose;
}

static void ferret_remote_input_plugin_init(FerretRemoteInputPlugin* self) {}

void ferret_remote_input_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  FerretRemoteInputPlugin* plugin = FERRET_REMOTE_INPUT_PLUGIN(
      g_object_new(ferret_remote_input_plugin_get_type(), nullptr));

  static FerretRemoteInputFerretRemoteInputPluginApiVTable api_vtable = {
    .get_platform_version = handle_get_platform_version
  };
  ferret_remote_input_ferret_remote_input_plugin_api_set_method_handlers(
    fl_plugin_registrar_get_messenger(registrar), nullptr,
    &api_vtable, g_object_ref(plugin), g_object_unref);

  g_object_unref(plugin);
}
