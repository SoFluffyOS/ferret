#include "desktop_window.h"

#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

static const char kChannel[] = "io.sofluffy.ferret/desktop";
static const char kGroup[] = "window";
static const int kDefaultWidth = 1100;
static const int kDefaultHeight = 720;

struct _DesktopWindow {
  GtkWindow* window;
  FlMethodChannel* channel;
  gboolean hide_on_close;
  gboolean started_hidden;
  gchar* state_path;
};

static gchar* state_path() {
  const gchar* home = g_getenv("FERRET_HOME");
  if (home != nullptr && home[0] != '\0') {
    return g_build_filename(home, "window.ini", nullptr);
  }
  return g_build_filename(g_get_home_dir(), ".sofluffy", "ferret",
                          "window.ini", nullptr);
}

static gboolean is_x11() {
#ifdef GDK_WINDOWING_X11
  return GDK_IS_X11_DISPLAY(gdk_display_get_default());
#else
  return FALSE;
#endif
}

// A place saved on a monitor that is gone would open the window off screen.
static gboolean on_some_monitor(int x, int y) {
  GdkDisplay* display = gdk_display_get_default();
  int count = gdk_display_get_n_monitors(display);
  for (int index = 0; index < count; index++) {
    GdkRectangle area;
    gdk_monitor_get_geometry(gdk_display_get_monitor(display, index), &area);
    if (x + 40 >= area.x && x + 40 < area.x + area.width && y + 40 >= area.y &&
        y + 40 < area.y + area.height) {
      return TRUE;
    }
  }
  return FALSE;
}

static void restore(DesktopWindow* self) {
  int width = kDefaultWidth;
  int height = kDefaultHeight;
  g_autoptr(GKeyFile) file = g_key_file_new();
  if (!g_key_file_load_from_file(file, self->state_path, G_KEY_FILE_NONE,
                                 nullptr)) {
    gtk_window_set_default_size(self->window, width, height);
    return;
  }

  int saved_width = g_key_file_get_integer(file, kGroup, "width", nullptr);
  int saved_height = g_key_file_get_integer(file, kGroup, "height", nullptr);
  if (saved_width >= 360 && saved_height >= 400) {
    width = saved_width;
    height = saved_height;
  }
  gtk_window_set_default_size(self->window, width, height);

  // Wayland leaves placing windows to the compositor.
  if (is_x11() && g_key_file_has_key(file, kGroup, "x", nullptr)) {
    int x = g_key_file_get_integer(file, kGroup, "x", nullptr);
    int y = g_key_file_get_integer(file, kGroup, "y", nullptr);
    if (on_some_monitor(x, y)) {
      gtk_window_move(self->window, x, y);
    }
  }

  if (g_key_file_get_boolean(file, kGroup, "maximized", nullptr)) {
    gtk_window_maximize(self->window);
  }
}

static void save(DesktopWindow* self) {
  if (self->window == nullptr ||
      !gtk_widget_get_visible(GTK_WIDGET(self->window))) {
    return;
  }

  g_autoptr(GKeyFile) file = g_key_file_new();
  gboolean maximized = gtk_window_is_maximized(self->window);
  g_key_file_set_boolean(file, kGroup, "maximized", maximized);
  if (!maximized) {
    int width = 0;
    int height = 0;
    gtk_window_get_size(self->window, &width, &height);
    g_key_file_set_integer(file, kGroup, "width", width);
    g_key_file_set_integer(file, kGroup, "height", height);
    if (is_x11()) {
      int x = 0;
      int y = 0;
      gtk_window_get_position(self->window, &x, &y);
      g_key_file_set_integer(file, kGroup, "x", x);
      g_key_file_set_integer(file, kGroup, "y", y);
    }
  }

  g_autofree gchar* directory = g_path_get_dirname(self->state_path);
  g_mkdir_with_parents(directory, 0700);
  g_key_file_save_to_file(file, self->state_path, nullptr);
}

static void show(DesktopWindow* self) {
  gtk_widget_show(GTK_WIDGET(self->window));
  gtk_window_present(self->window);
}

static void hide(DesktopWindow* self) {
  save(self);
  gtk_widget_hide(GTK_WIDGET(self->window));
}

static gboolean on_delete(GtkWidget* widget, GdkEvent* event,
                          gpointer user_data) {
  DesktopWindow* self = static_cast<DesktopWindow*>(user_data);
  if (!self->hide_on_close) {
    save(self);
    return FALSE;
  }

  hide(self);
  if (self->channel != nullptr) {
    fl_method_channel_invoke_method(self->channel, "window.closedToTray",
                                    nullptr, nullptr, nullptr, nullptr);
  }
  return TRUE;
}

static void on_destroy(GtkWidget* widget, gpointer user_data) {
  DesktopWindow* self = static_cast<DesktopWindow*>(user_data);
  self->window = nullptr;
}

static void on_call(FlMethodChannel* channel, FlMethodCall* call,
                    gpointer user_data) {
  DesktopWindow* self = static_cast<DesktopWindow*>(user_data);
  const gchar* method = fl_method_call_get_name(call);
  if (self->window == nullptr) {
    fl_method_call_respond_success(call, nullptr, nullptr);
    return;
  }

  FlValue* args = fl_method_call_get_args(call);
  g_autoptr(FlValue) result = nullptr;

  if (g_strcmp0(method, "window.setHideOnClose") == 0) {
    FlValue* value = nullptr;
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      value = fl_value_lookup_string(args, "value");
    }
    self->hide_on_close = value != nullptr &&
                          fl_value_get_type(value) == FL_VALUE_TYPE_BOOL &&
                          fl_value_get_bool(value);
  } else if (g_strcmp0(method, "window.show") == 0) {
    show(self);
  } else if (g_strcmp0(method, "window.hide") == 0) {
    hide(self);
  } else if (g_strcmp0(method, "window.toggle") == 0) {
    if (gtk_widget_get_visible(GTK_WIDGET(self->window)) &&
        gtk_window_is_active(self->window)) {
      hide(self);
    } else {
      show(self);
    }
  } else if (g_strcmp0(method, "window.quit") == 0) {
    save(self);
    g_application_quit(g_application_get_default());
  } else if (g_strcmp0(method, "window.startedHidden") == 0) {
    result = fl_value_new_bool(self->started_hidden);
  } else {
    fl_method_call_respond_not_implemented(call, nullptr);
    return;
  }

  fl_method_call_respond_success(call, result, nullptr);
}

DesktopWindow* desktop_window_new(GtkWindow* window, gboolean started_hidden) {
  DesktopWindow* self = g_new0(DesktopWindow, 1);
  self->window = window;
  self->started_hidden = started_hidden;
  self->state_path = state_path();
  restore(self);
  g_signal_connect(window, "delete-event", G_CALLBACK(on_delete), self);
  g_signal_connect(window, "destroy", G_CALLBACK(on_destroy), self);
  return self;
}

void desktop_window_attach(DesktopWindow* self, FlView* view) {
  FlEngine* engine = fl_view_get_engine(view);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(engine), kChannel, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(self->channel, on_call, self,
                                            nullptr);
}

gboolean desktop_window_shows_at_start(DesktopWindow* self) {
  return !self->started_hidden;
}

void desktop_window_free(DesktopWindow* self) {
  if (self == nullptr) {
    return;
  }
  save(self);
  if (self->window != nullptr) {
    g_signal_handlers_disconnect_by_data(self->window, self);
  }
  g_clear_object(&self->channel);
  g_free(self->state_path);
  g_free(self);
}
