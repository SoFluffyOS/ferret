#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  // A second launch hands over to the running Ferret, which then brings
  // its window up. Windows lets a background app take the foreground only
  // when the app the person just started allows it, so this one does.
  HANDLE running =
      ::CreateMutexW(nullptr, FALSE, L"Local\\io.sofluffy.ferret.running");
  if (running != nullptr && ::GetLastError() == ERROR_ALREADY_EXISTS) {
    ::AllowSetForegroundWindow(ASFW_ANY);
  }

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();
  bool started_hidden = false;
  for (const std::string& argument : command_line_arguments) {
    if (argument == "--hidden") {
      started_hidden = true;
    }
  }

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project, started_hidden);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1100, 720);
  if (!window.Create(L"Ferret", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  if (running != nullptr) {
    ::CloseHandle(running);
  }
  return EXIT_SUCCESS;
}
