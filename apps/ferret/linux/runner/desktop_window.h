#ifndef RUNNER_DESKTOP_WINDOW_H_
#define RUNNER_DESKTOP_WINDOW_H_

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

// The window's side of the io.sofluffy.ferret/desktop channel: hide on close
// while a tray icon exists, show and hide on request, and the window's size
// (and place, on X11) kept in <FERRET_HOME or ~/.sofluffy/ferret>/window.ini.
// The tray icon itself is drawn from Dart over D-Bus.
typedef struct _DesktopWindow DesktopWindow;

// Sizes `window` from the saved state. `started_hidden` is true when Ferret
// was started with --hidden, as autostart does.
DesktopWindow* desktop_window_new(GtkWindow* window, gboolean started_hidden);

// Listens on the channel once the Flutter view exists.
void desktop_window_attach(DesktopWindow* self, FlView* view);

// Whether the first frame should show the window.
gboolean desktop_window_shows_at_start(DesktopWindow* self);

void desktop_window_free(DesktopWindow* self);

#endif  // RUNNER_DESKTOP_WINDOW_H_
