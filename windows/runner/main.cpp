#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "run_loop.h"
#include "utils.h"
#include "window_configuration.h"



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


#include "cython.h"
#include "my_utils.h"
#include "resource.h"
#include "firebase_commons.h"


// #ifdef NDEBUG
// int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
//                       _In_ wchar_t *command_line, _In_ int show_command) {

    
// #else
int main() {
// #ifdef NDEBUG
// HWND consoleWnd = GetConsoleWindow();
//   DWORD dwProcessId;
//   GetWindowThreadProcessId(consoleWnd, &dwProcessId);
//   if (GetCurrentProcessId()==dwProcessId)
//     ::ShowWindow(::GetConsoleWindow(), SW_HIDE);
// std::wstring dirPath = getLocalAppDataFolder();
//    DeleteFileW((dirPath + L"\\log.txt").c_str());
//    std::remove("log.txt");

//    FILE* unused;
//    if (freopen_s(&unused,  ws2s(dirPath + L"\\log.txt").c_str(), "w", stdout)) {
//       _dup2(_fileno(stdout), 1);
//     }
//     if (freopen_s(&unused,  ws2s(dirPath + L"\\log.txt").c_str(), "w", stderr)) {
//       _dup2(_fileno(stdout), 2);
//     }
//     std::ios::sync_with_stdio();
// #endif
  // printf("1");
  // HWND consoleWnd = GetConsoleWindow();
  // DWORD dwProcessId;
  // GetWindowThreadProcessId(consoleWnd, &dwProcessId);
  // if (GetCurrentProcessId()==dwProcessId)
  //   ::ShowWindow(::GetConsoleWindow(), SW_HIDE);
  // printf("2");
  // std::wstring dirPath = getLocalAppDataFolder();
  //  DeleteFileW((dirPath + L"\\log.txt").c_str());
  //  std::remove("log.txt");

  //  FILE *unused;
  //   printf("3");
  //   if (freopen_s(&unused, ws2s(dirPath + L"\\log.txt").c_str(), "w", stdout)==0) {
  //     _dup2(_fileno(stdout), 1);
  //   }
  //   if (freopen_s(&unused, ws2s(dirPath + L"\\log.txt").c_str(), "w", stderr)==0) {
  //     _dup2(_fileno(stdout), 2);
  //   }
  //  std::ios::sync_with_stdio();

   //FlutterDesktopResyncOutputStreams();

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  // if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
  //   CreateAndAttachConsole();
  // }
  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
//   #ifdef _WIN32
//      SetConsoleCtrlHandler((PHANDLER_ROUTINE)SignalHandler, TRUE);
// #else
//      signal(SIGINT, SignalHandler);
// #endif  // _WIN32
    if (!isAlreadyRunning())
        return common_main();
    else
        return -1;
  

// #ifdef NDEBUG
//   if(unused != nullptr)
//    fclose(unused);
// #endif
  ::CoUninitialize();
  return EXIT_SUCCESS;
}

int runFlutterCode()
{
  RunLoop run_loop;

  flutter::DartProject project(L"data");
  std::vector<std::string> vect;
  
  vect.push_back("verbose-logging");
  project.SetEngineSwitches(vect);
  FlutterWindow window(&run_loop, project);
  Win32Window::Point origin(kFlutterWindowOriginX, kFlutterWindowOriginY);
  Win32Window::Size size(kFlutterWindowWidth, kFlutterWindowHeight);
  if (!window.CreateAndShow(kFlutterWindowTitle, origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  run_loop.Run();
  return EXIT_SUCCESS;  
}
