#include "include/ferret_drop/ferret_drop_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gio/gio.h>
#include <gtk/gtk.h>

#include "ferret_drop_plugin_private.h"
#include "messages.g.h"

#define FERRET_DROP_PLUGIN(obj)                                     \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), ferret_drop_plugin_get_type(), \
                              FerretDropPlugin))

struct _FerretDropPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(FerretDropPlugin, ferret_drop_plugin, g_object_get_type())

gchar* ferret_drop_plugin_uri_for_existing_file(const gchar* path) {
  if (path == nullptr || *path == '\0' ||
      !g_file_test(path, G_FILE_TEST_EXISTS)) {
    return nullptr;
  }

  g_autoptr(GFile) file = g_file_new_for_path(path);
  return g_file_get_uri(file);
}

static gboolean launch_uri(const gchar* uri) {
  g_autoptr(GError) error = nullptr;
  if (!g_app_info_launch_default_for_uri(uri, nullptr, &error)) {
    g_warning("ferret_drop: could not open a received file: %s",
              error->message);
    return FALSE;
  }

  return TRUE;
}

// Asks the file manager to select the file (org.freedesktop.FileManager1),
// which Nautilus, Dolphin, Nemo and Thunar implement.
static gboolean show_in_file_manager(const gchar* uri) {
  g_autoptr(GError) error = nullptr;
  g_autoptr(GDBusConnection) bus =
      g_bus_get_sync(G_BUS_TYPE_SESSION, nullptr, &error);
  if (bus == nullptr) {
    return FALSE;
  }

  const gchar* uris[] = {uri, nullptr};
  g_autoptr(GVariant) reply = g_dbus_connection_call_sync(
      bus, "org.freedesktop.FileManager1", "/org/freedesktop/FileManager1",
      "org.freedesktop.FileManager1", "ShowItems",
      g_variant_new("(^ass)", uris, ""), nullptr, G_DBUS_CALL_FLAGS_NONE, 3000,
      nullptr, &error);
  return reply != nullptr;
}

static FerretDropFerretDropHostApiTakePendingSharesResponse*
handle_take_pending_shares(gpointer user_data) {
  g_autoptr(FlValue) shares = fl_value_new_list();
  return ferret_drop_ferret_drop_host_api_take_pending_shares_response_new(
      shares);
}

// File managers here start "ferret send" with the files, and the app asks
// which device, so there is no list to publish.
static FerretDropFerretDropHostApiSetShareTargetsResponse*
handle_set_share_targets(FlValue* targets, gpointer user_data) {
  return ferret_drop_ferret_drop_host_api_set_share_targets_response_new();
}

static FerretDropFerretDropHostApiCanSaveToDownloadsResponse*
handle_can_save_to_downloads(gpointer user_data) {
  return ferret_drop_ferret_drop_host_api_can_save_to_downloads_response_new(
      FALSE);
}

static void handle_save_to_downloads(
    const gchar* source_path, const gchar* file_name, const gchar* mime_type,
    const gchar* folder, FerretDropFerretDropHostApiResponseHandle* handle,
    gpointer user_data) {
  ferret_drop_ferret_drop_host_api_respond_error_save_to_downloads(
      handle, "unsupported", "Save the file in the receive folder instead",
      nullptr);
}

static FerretDropFerretDropHostApiOpenResponse* handle_open(
    const gchar* location, const gchar* mime_type, gpointer user_data) {
  g_autofree gchar* uri = ferret_drop_plugin_uri_for_existing_file(location);
  gboolean opened = uri != nullptr && launch_uri(uri);
  return ferret_drop_ferret_drop_host_api_open_response_new(opened);
}

static FerretDropFerretDropHostApiRevealResponse* handle_reveal(
    const gchar* location, gpointer user_data) {
  g_autofree gchar* uri = ferret_drop_plugin_uri_for_existing_file(location);
  if (uri == nullptr) {
    return ferret_drop_ferret_drop_host_api_reveal_response_new(FALSE);
  }

  if (show_in_file_manager(uri)) {
    return ferret_drop_ferret_drop_host_api_reveal_response_new(TRUE);
  }

  g_autofree gchar* folder = g_path_get_dirname(location);
  g_autofree gchar* folder_uri =
      ferret_drop_plugin_uri_for_existing_file(folder);
  gboolean opened = folder_uri != nullptr && launch_uri(folder_uri);
  return ferret_drop_ferret_drop_host_api_reveal_response_new(opened);
}

static void ferret_drop_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(ferret_drop_plugin_parent_class)->dispose(object);
}

static void ferret_drop_plugin_class_init(FerretDropPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = ferret_drop_plugin_dispose;
}

static void ferret_drop_plugin_init(FerretDropPlugin* self) {}

void ferret_drop_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  FerretDropPlugin* plugin = FERRET_DROP_PLUGIN(
      g_object_new(ferret_drop_plugin_get_type(), nullptr));

  static FerretDropFerretDropHostApiVTable api_vtable = {
      .take_pending_shares = handle_take_pending_shares,
      .set_share_targets = handle_set_share_targets,
      .can_save_to_downloads = handle_can_save_to_downloads,
      .save_to_downloads = handle_save_to_downloads,
      .open = handle_open,
      .reveal = handle_reveal,
  };
  ferret_drop_ferret_drop_host_api_set_method_handlers(
      fl_plugin_registrar_get_messenger(registrar), nullptr, &api_vtable,
      g_object_ref(plugin), g_object_unref);

  g_object_unref(plugin);
}
