#include "ferret_clipboard_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <flutter/plugin_registrar_windows.h>

#include <cstring>
#include <memory>
#include <string>
#include <vector>

#include "image_codec.h"
#include "messages.g.h"

namespace ferret_clipboard {

namespace {

constexpr wchar_t kPngFormat[] = L"PNG";
constexpr wchar_t kExcludeFromMonitors[] =
    L"ExcludeClipboardContentFromMonitorProcessing";
constexpr wchar_t kCanIncludeInHistory[] = L"CanIncludeInClipboardHistory";
constexpr wchar_t kCanUploadToCloud[] = L"CanUploadToCloudClipboard";
constexpr wchar_t kViewerIgnore[] = L"Clipboard Viewer Ignore";

// Holds the clipboard open for one scope. Another app may hold it for a
// moment, so opening retries a few times.
class ClipboardLock {
 public:
  explicit ClipboardLock(HWND owner) {
    for (int attempt = 0; attempt < 5 && !open_; ++attempt) {
      open_ = OpenClipboard(owner) != FALSE;
      if (!open_) {
        Sleep(10);
      }
    }
  }

  ~ClipboardLock() {
    if (open_) {
      CloseClipboard();
    }
  }

  ClipboardLock(const ClipboardLock&) = delete;
  ClipboardLock& operator=(const ClipboardLock&) = delete;

  bool is_open() const { return open_; }

 private:
  bool open_ = false;
};

std::optional<std::vector<uint8_t>> ReadFormat(UINT format) {
  HANDLE handle = GetClipboardData(format);
  if (handle == nullptr) {
    return std::nullopt;
  }

  const SIZE_T size = GlobalSize(handle);
  const void* data = GlobalLock(handle);
  if (data == nullptr) {
    return std::nullopt;
  }

  std::vector<uint8_t> bytes(static_cast<const uint8_t*>(data),
                             static_cast<const uint8_t*>(data) + size);
  GlobalUnlock(handle);
  return bytes;
}

bool SetFormat(UINT format, const void* data, size_t size) {
  HGLOBAL memory = GlobalAlloc(GMEM_MOVEABLE, size);
  if (memory == nullptr) {
    return false;
  }

  void* target = GlobalLock(memory);
  if (target == nullptr) {
    GlobalFree(memory);
    return false;
  }

  std::memcpy(target, data, size);
  GlobalUnlock(memory);
  if (SetClipboardData(format, memory) == nullptr) {
    GlobalFree(memory);
    return false;
  }
  return true;
}

std::optional<std::string> ReadText() {
  HANDLE handle = GetClipboardData(CF_UNICODETEXT);
  if (handle == nullptr) {
    return std::nullopt;
  }

  const wchar_t* wide = static_cast<const wchar_t*>(GlobalLock(handle));
  if (wide == nullptr) {
    return std::nullopt;
  }

  const int length = WideCharToMultiByte(CP_UTF8, 0, wide, -1, nullptr, 0,
                                         nullptr, nullptr);
  std::string text;
  if (length > 1) {
    text.resize(static_cast<size_t>(length - 1));
    WideCharToMultiByte(CP_UTF8, 0, wide, -1, text.data(), length, nullptr,
                        nullptr);
  }
  GlobalUnlock(handle);

  if (text.empty()) {
    return std::nullopt;
  }
  return text;
}

bool WriteText(const std::string& text) {
  const int length = MultiByteToWideChar(CP_UTF8, 0, text.c_str(), -1,
                                         nullptr, 0);
  if (length <= 0) {
    return false;
  }

  std::wstring wide(static_cast<size_t>(length), L'\0');
  MultiByteToWideChar(CP_UTF8, 0, text.c_str(), -1, wide.data(), length);
  return SetFormat(CF_UNICODETEXT, wide.c_str(),
                   static_cast<size_t>(length) * sizeof(wchar_t));
}

// Password managers mark secrets with formats that ask clipboard monitors,
// history and cloud sync to leave them alone.
bool IsSensitive() {
  if (IsClipboardFormatAvailable(
          RegisterClipboardFormatW(kExcludeFromMonitors)) ||
      IsClipboardFormatAvailable(RegisterClipboardFormatW(kViewerIgnore))) {
    return true;
  }

  const UINT history_format = RegisterClipboardFormatW(kCanIncludeInHistory);
  if (!IsClipboardFormatAvailable(history_format)) {
    return false;
  }

  std::optional<std::vector<uint8_t>> value = ReadFormat(history_format);
  if (!value || value->size() < sizeof(DWORD)) {
    return false;
  }

  DWORD allowed = 1;
  std::memcpy(&allowed, value->data(), sizeof(DWORD));
  return allowed == 0;
}

void MarkSensitive() {
  const DWORD no = 0;
  SetFormat(RegisterClipboardFormatW(kExcludeFromMonitors), &no, sizeof(no));
  SetFormat(RegisterClipboardFormatW(kCanIncludeInHistory), &no, sizeof(no));
  SetFormat(RegisterClipboardFormatW(kCanUploadToCloud), &no, sizeof(no));
}

std::optional<std::vector<uint8_t>> ReadImageAsPng() {
  const UINT png_format = RegisterClipboardFormatW(kPngFormat);
  if (IsClipboardFormatAvailable(png_format)) {
    std::optional<std::vector<uint8_t>> png = ReadFormat(png_format);
    if (png && !png->empty()) {
      return png;
    }
  }

  for (UINT format : {static_cast<UINT>(CF_DIBV5), static_cast<UINT>(CF_DIB)}) {
    if (!IsClipboardFormatAvailable(format)) {
      continue;
    }

    std::optional<std::vector<uint8_t>> dib = ReadFormat(format);
    if (!dib) {
      continue;
    }

    std::optional<std::vector<uint8_t>> png = DibToPng(dib->data(), dib->size());
    if (png) {
      return png;
    }
  }
  return std::nullopt;
}

bool WriteImage(const std::vector<uint8_t>& image, const std::string& mime) {
  std::optional<std::vector<uint8_t>> png;
  if (mime == "image/png") {
    png = image;
  } else {
    png = ImageToPng(image);
  }

  std::optional<std::vector<uint8_t>> dib = ImageToDib(image);
  bool wrote = false;
  if (png) {
    wrote = SetFormat(RegisterClipboardFormatW(kPngFormat), png->data(),
                      png->size()) ||
            wrote;
  }
  if (dib) {
    wrote = SetFormat(CF_DIB, dib->data(), dib->size()) || wrote;
  }
  return wrote;
}

}  // namespace

// static
void FerretClipboardPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto plugin = std::make_unique<FerretClipboardPlugin>(registrar);
  ClipboardHostApi::SetUp(registrar->messenger(), plugin.get());
  registrar->AddPlugin(std::move(plugin));
}

FerretClipboardPlugin::FerretClipboardPlugin(
    flutter::PluginRegistrarWindows* registrar)
    : registrar_(registrar),
      flutter_api_(std::make_unique<ClipboardFlutterApi>(
          registrar->messenger())) {
  window_proc_id_ = registrar_->RegisterTopLevelWindowProcDelegate(
      [this](HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
        return HandleWindowProc(hwnd, message, wparam, lparam);
      });
}

FerretClipboardPlugin::~FerretClipboardPlugin() {
  StopWatching();
  registrar_->UnregisterTopLevelWindowProcDelegate(window_proc_id_);
}

HWND FerretClipboardPlugin::TopLevelWindow() const {
  flutter::FlutterView* view = registrar_->GetView();
  if (view == nullptr) {
    return nullptr;
  }
  return GetAncestor(view->GetNativeWindow(), GA_ROOT);
}

ErrorOr<std::optional<PlatformClip>> FerretClipboardPlugin::Read() {
  ClipboardLock lock(TopLevelWindow());
  if (!lock.is_open()) {
    return std::optional<PlatformClip>();
  }

  const bool sensitive = IsSensitive();
  if (std::optional<std::string> text = ReadText()) {
    PlatformClip clip(sensitive);
    clip.set_text(*text);
    return std::optional<PlatformClip>(clip);
  }

  if (std::optional<std::vector<uint8_t>> png = ReadImageAsPng()) {
    PlatformClip clip(sensitive);
    clip.set_image(*png);
    clip.set_image_mime("image/png");
    return std::optional<PlatformClip>(clip);
  }

  return std::optional<PlatformClip>();
}

std::optional<FlutterError> FerretClipboardPlugin::Write(
    const PlatformClip& clip) {
  ClipboardLock lock(TopLevelWindow());
  if (!lock.is_open()) {
    return FlutterError("busy", "Another app is using the clipboard.");
  }

  if (!EmptyClipboard()) {
    return FlutterError("write-failed", "Could not clear the clipboard.");
  }

  bool wrote = false;
  if (const std::string* text = clip.text()) {
    wrote = WriteText(*text);
  } else if (const std::vector<uint8_t>* image = clip.image()) {
    const std::string* mime = clip.image_mime();
    wrote = WriteImage(*image, mime == nullptr ? std::string() : *mime);
  }

  if (!wrote) {
    return FlutterError("write-failed", "Could not write to the clipboard.");
  }

  if (clip.sensitive()) {
    MarkSensitive();
  }

  own_write_sequence_ = GetClipboardSequenceNumber();
  return std::nullopt;
}

std::optional<FlutterError> FerretClipboardPlugin::StartWatching() {
  if (listening_window_ != nullptr) {
    return std::nullopt;
  }

  HWND window = TopLevelWindow();
  if (window == nullptr || !AddClipboardFormatListener(window)) {
    return FlutterError("watch-failed", "Could not watch the clipboard.");
  }

  listening_window_ = window;
  return std::nullopt;
}

std::optional<FlutterError> FerretClipboardPlugin::StopWatching() {
  if (listening_window_ == nullptr) {
    return std::nullopt;
  }

  RemoveClipboardFormatListener(listening_window_);
  listening_window_ = nullptr;
  return std::nullopt;
}

std::optional<LRESULT> FerretClipboardPlugin::HandleWindowProc(
    HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
  if (message != WM_CLIPBOARDUPDATE || listening_window_ == nullptr) {
    return std::nullopt;
  }

  if (GetClipboardSequenceNumber() == own_write_sequence_) {
    return std::nullopt;
  }

  flutter_api_->OnChanged([] {}, [](const FlutterError&) {});
  return std::nullopt;
}

}  // namespace ferret_clipboard
