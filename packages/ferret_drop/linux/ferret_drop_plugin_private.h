#include <flutter_linux/flutter_linux.h>

#include "include/ferret_drop/ferret_drop_plugin.h"

// Exposed for unit tests.

// Returns the file:// URI of [path] when the file exists, or nullptr. The
// caller frees the result.
gchar* ferret_drop_plugin_uri_for_existing_file(const gchar* path);
