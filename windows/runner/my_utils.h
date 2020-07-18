#include "firebase_commons.h"



extern int runFlutterCode();

int common_main() {


   std::wstring dirPath = getLocalAppDataFolder();
   DeleteFileW((dirPath + L"\\ai_loaded").c_str());
   std::remove("ai_loaded");
   
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

