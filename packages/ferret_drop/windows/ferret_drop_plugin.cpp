#include "ferret_drop_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <shellapi.h>
#include <shlobj.h>

#include <flutter/plugin_registrar_windows.h>

#include <memory>
#include <string>

#include "messages.g.h"

namespace ferret_drop {

std::wstring Utf16FromUtf8(const std::string& utf8) {
  if (utf8.empty()) {
    return std::wstring();
  }

  const int length = ::MultiByteToWideChar(
      CP_UTF8, MB_ERR_INVALID_CHARS, utf8.data(),
      static_cast<int>(utf8.size()), nullptr, 0);
  if (length <= 0) {
    return std::wstring();
  }

  std::wstring utf16(length, L'\0');
  ::MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, utf8.data(),
                        static_cast<int>(utf8.size()), utf16.data(), length);
  return utf16;
}

namespace {

bool FileExists(const std::wstring& path) {
  return ::GetFileAttributesW(path.c_str()) != INVALID_FILE_ATTRIBUTES;
}

}  // namespace

// static
void FerretDropPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto plugin = std::make_unique<FerretDropPlugin>();
  FerretDropHostApi::SetUp(registrar->messenger(), plugin.get());
  registrar->AddPlugin(std::move(plugin));
}

FerretDropPlugin::FerretDropPlugin() {}

FerretDropPlugin::~FerretDropPlugin() {}

ErrorOr<::flutter::EncodableList> FerretDropPlugin::TakePendingShares() {
  return ::flutter::EncodableList();
}

ErrorOr<bool> FerretDropPlugin::CanSaveToDownloads() { return false; }

void FerretDropPlugin::SaveToDownloads(
    const std::string& source_path, const std::string& file_name,
    const std::string& mime_type, const std::string& folder,
    std::function<void(ErrorOr<SavedFile> reply)> result) {
  result(FlutterError("unsupported",
                      "Save the file in the receive folder instead"));
}

ErrorOr<bool> FerretDropPlugin::Open(const std::string& location,
                                     const std::string& mime_type) {
  const std::wstring path = Utf16FromUtf8(location);
  if (path.empty() || !FileExists(path)) {
    return false;
  }

  const HINSTANCE opened = ::ShellExecuteW(nullptr, L"open", path.c_str(),
                                           nullptr, nullptr, SW_SHOWNORMAL);
  return reinterpret_cast<INT_PTR>(opened) > 32;
}

ErrorOr<bool> FerretDropPlugin::Reveal(const std::string& location) {
  const std::wstring path = Utf16FromUtf8(location);
  if (path.empty() || !FileExists(path)) {
    return false;
  }

  PIDLIST_ABSOLUTE item = nullptr;
  if (FAILED(::SHParseDisplayName(path.c_str(), nullptr, &item, 0, nullptr))) {
    return false;
  }

  const HRESULT shown = ::SHOpenFolderAndSelectItems(item, 0, nullptr, 0);
  ::CoTaskMemFree(item);
  return SUCCEEDED(shown);
}

}  // namespace ferret_drop
