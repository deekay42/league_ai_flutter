#include "firebase_commons.h"
#include <flutter_windows.h>
#include <io.h>
#include <stdio.h>
#include <windows.h>

#include <iostream>

extern int runFlutterCode();

std::string ws2s(const std::wstring& wstr)
{
    using convert_typeX = std::codecvt_utf8<wchar_t>;
    std::wstring_convert<convert_typeX, wchar_t> converterX;

    return converterX.to_bytes(wstr);
}

int common_main() {


   std::wstring dirPath = getLocalAppDataFolder();
   DeleteFileW((dirPath + L"\\ai_loaded").c_str());
   DeleteFileW((dirPath + L"\\terminate").c_str());
   std::remove("ai_loaded");
   std::remove("terminate");

   // FILE* unused;
   // if (freopen_s(&unused,  ws2s(dirPath + L"\\log.txt").c_str(), "w", stdout)) {
   //    _dup2(_fileno(stdout), 1);
   //  }
   //  if (freopen_s(&unused,  ws2s(dirPath + L"\\log.txt").c_str(), "w", stderr)) {
   //    _dup2(_fileno(stdout), 2);
   //  }
   //  std::ios::sync_with_stdio();
    //FlutterDesktopResyncOutputStreams();

   printf("Now running python code\n");
   std::thread cythonThread(runCythonCode);
   printf("Python code complete\n");
   std::cout << "now runnning flutter" << std::endl;
   runFlutterCode();
   std::ofstream outfile(getLocalAppDataFolder() + L"\\terminate");
   outfile << "terminate" << std::endl;
   outfile.close();
   std::cout << "runnning flutter complete" << std::endl;
   std::cout << "Waiting for join" << std::endl;
   
  cythonThread.join();
  std::cout << "join complete" << std::endl;

 #ifndef NDEBUG
  // Wait until the user wants to quit the app.
  while (!ProcessEvents(1000)) {
  }

 #endif
  
   return 0;
}

