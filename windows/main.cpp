#include <flutter/flutter_view_controller.h>
#define NOMINMAX
#include <windows.h>

#include <chrono>
#include <codecvt>
#include <iostream>
#include <string>
#include <vector>

#include <inttypes.h>
#include <stdarg.h>
#include <algorithm>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <sstream>
#include <thread>
#include <fstream>

#ifdef _DEBUG
#undef _DEBUG
#include "Python.h"
#define _DEBUG
#else
#include <Python.h>
#endif

#include "flutter/generated_plugin_registrant.h"
#include "win32_window.h"
#include "window_configuration.h"

#include "cython.h"
#include "resource.h"
#include "firebase_commons.h"



int runFlutterCode();


namespace {

// Returns the path of the directory containing this executable, or an empty
// string if the directory cannot be found.
std::string GetExecutableDirectory() {
  wchar_t buffer[MAX_PATH];
  if (GetModuleFileName(nullptr, buffer, MAX_PATH) == 0) {
    std::cerr << "Couldn't locate executable" << std::endl;
    return "";
  }
  std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>> wide_to_utf8;
  std::string executable_path = wide_to_utf8.to_bytes(buffer);
  size_t last_separator_position = executable_path.find_last_of('\\');
  if (last_separator_position == std::string::npos) {
    std::cerr << "Unabled to find parent directory of " << executable_path
              << std::endl;
    return "";
  }
  return executable_path.substr(0, last_separator_position);
}

}  // namespace


int common_main() {


   std::wstring dirPath = getLocalAppDataFolder();
   DeleteFileW((dirPath + L"\\ai_loaded").c_str());
   std::remove("ai_loaded");
   

   std::cout << "now runnning flutter" << std::endl;
   std::thread flutterThread(runFlutterCode);
   std::cout << "runnning flutter complete" << std::endl;

   printf("Now running python code\n");
   runCythonCode();
   printf("Python code complete\n");

  

  //std::ofstream outfile(getLocalAppDataFolder() + L"\\terminate");
  //outfile << "terminate" << std::endl;
  //outfile.close();

  

 

  //std::cout << "Waiting for join" << std::endl;
  //pythonThread.join();
  //std::cout << "join complete" << std::endl;

 #ifdef _DEBUG
  // Wait until the user wants to quit the app.
  while (!ProcessEvents(1000)) {
  }

 #endif
  
   return 0;
}


#ifdef _DEBUG
int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
    _In_ wchar_t* command_line, _In_ int show_command) {
#else
int main() {
    // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  //  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    //    ::AllocConsole();
#endif
        
//FILE* fDummy;
        
//freopen_s(&fDummy, "CONIN$", "r", stdin);
        
//freopen_s(&fDummy, "CONOUT$", "w", stderr);
        
//freopen_s(&fDummy, "CONOUT$", "w", stdout);
 //   }


    //ChangeToFileDirectory(
     //   FIREBASE_CONFIG_STRING[0] != '\0' ?
     //     FIREBASE_CONFIG_STRING : argv[0]);  // NOLINT
#ifdef _WIN32
     SetConsoleCtrlHandler((PHANDLER_ROUTINE)SignalHandler, TRUE);
#else
     signal(SIGINT, SignalHandler);
#endif  // _WIN32
    if (!isAlreadyRunning())
        return common_main();
    else
        return -1;
}


int runFlutterCode() {

  // Resources are located relative to the executable.
  std::string base_directory = GetExecutableDirectory();
  if (base_directory.empty()) {
    base_directory = ".";
  }
  std::string data_directory = base_directory + "\\data";
  std::string assets_path = data_directory + "\\flutter_assets";
  std::string icu_data_path = data_directory + "\\icudtl.dat";

  // Arguments for the Flutter Engine.
  std::vector<std::string> arguments;
#ifndef _DEBUG
  arguments.push_back("--disable-observatory");
  arguments.push_back("--disable-dart-asserts");
#endif

  // Top-level window frame.
  Win32Window::Point origin(kFlutterWindowOriginX, kFlutterWindowOriginY);
  Win32Window::Size size(kFlutterWindowWidth, kFlutterWindowHeight);

  flutter::FlutterViewController flutter_controller(
      icu_data_path, size.width, size.height, assets_path, arguments);
  RegisterPlugins(&flutter_controller);

  // Create a top-level win32 window to host the Flutter view.
  Win32Window window;
  if (!window.CreateAndShow(kFlutterWindowTitle, origin, size)) {
    return EXIT_FAILURE;
  }

  // Parent and resize Flutter view into top-level window.
  window.SetChildContent(flutter_controller.view()->GetNativeWindow());

  // Run messageloop with a hook for flutter_controller to do work until
  // the window is closed.
  std::chrono::nanoseconds wait_duration(0);
  // Run until the window is closed.
  while (window.GetHandle() != nullptr) {
    MsgWaitForMultipleObjects(0, nullptr, FALSE,
                              static_cast<DWORD>(wait_duration.count() / 1000),
                              QS_ALLINPUT);
    MSG message;
    // All pending Windows messages must be processed; MsgWaitForMultipleObjects
    // won't return again for items left in the queue after PeekMessage.
    while (PeekMessage(&message, nullptr, 0, 0, PM_REMOVE)) {
      if (message.message == WM_QUIT) {
        window.Destroy();
        break;
      }
      TranslateMessage(&message);
      DispatchMessage(&message);
    }
    // Allow Flutter to process its messages.
    // TODO: Consider interleaving processing on a per-message basis to avoid
    // the possibility of one queue starving the other.
    wait_duration = flutter_controller.ProcessMessages();
  }

  std::ofstream outfile(getLocalAppDataFolder() + L"\\terminate");
  outfile << "terminate" << std::endl;
  outfile.close();

  return EXIT_SUCCESS;
}
