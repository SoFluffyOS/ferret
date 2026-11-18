#ifndef FLUTTER_PLUGIN_FERRET_DROP_PLUGIN_H_
#define FLUTTER_PLUGIN_FERRET_DROP_PLUGIN_H_

#include <flutter/plugin_registrar_windows.h>

#include <functional>
#include <memory>
#include <string>

#include "messages.g.h"

namespace ferret_drop {

// Opens received files and shows them in Explorer.
class FerretDropPlugin : public flutter::Plugin, public FerretDropHostApi {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  FerretDropPlugin();

  virtual ~FerretDropPlugin();

  FerretDropPlugin(const FerretDropPlugin&) = delete;
  FerretDropPlugin& operator=(const FerretDropPlugin&) = delete;

  ErrorOr<::flutter::EncodableList> TakePendingShares() override;
  std::optional<FlutterError> SetShareTargets(
      const ::flutter::EncodableList& targets) override;
  ErrorOr<bool> CanSaveToDownloads() override;
  void SaveToDownloads(
      const std::string& source_path, const std::string& file_name,
      const std::string& mime_type, const std::string& folder,
      std::function<void(ErrorOr<SavedFile> reply)> result) override;
  ErrorOr<bool> Open(const std::string& location,
                     const std::string& mime_type) override;
  ErrorOr<bool> Reveal(const std::string& location) override;
};

// Converts UTF-8 from Dart to the UTF-16 Windows APIs take.
std::wstring Utf16FromUtf8(const std::string& utf8);

}  // namespace ferret_drop

#endif  // FLUTTER_PLUGIN_FERRET_DROP_PLUGIN_H_
