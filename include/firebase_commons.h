#pragma once

#include ".\common.h"

#include "firebase/app.h"
#include "firebase/auth.h"
#include "firebase/database.h"
#include "firebase/functions.h"
#include "firebase/future.h"
#include "firebase/log.h"
#include <stdlib.h>  
#include <signal.h>  
#include <tchar.h>  
#include <signal.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdexcept>
#include <sstream>
#include <iostream>
#include <string>
#include <fstream>

#include <shlwapi.h>
#include "shlobj.h"

#ifdef _WIN32
#include <direct.h>
#define chdir _chdir
#else
#include <unistd.h>
#endif  // _WIN32

#ifdef _WIN32
#include <windows.h>
#endif  // _WIN32


extern ::firebase::App *app;
extern ::firebase::database::Database *database;

extern firebase::Future<firebase::auth::User *> user_future;
extern firebase::auth::User *user;
extern ::firebase::functions::Functions *functions;
extern ::firebase::auth::Auth *auth;
extern std::string myuid;
extern std::string mysecret;

std::wstring getLocalAppDataFolder();

// Wait for a Future to be completed. If the Future returns an error, it will
// be logged.
void WaitForCompletion(const firebase::FutureBase &future, const char *name);

firebase::Variant callFBFunctionSync(
    const char *functionName,
    std::map<std::string, firebase::Variant> *data = nullptr);


class UIDListener : public firebase::database::ValueListener {
 public:
  firebase::database::DatabaseReference myRef;

 public:
  UIDListener(firebase::database::DatabaseReference myRef) : myRef(myRef) {}
  ~UIDListener()
  {
	  printf("deleting listener now\n");
	  printf("Removing value!\n");
	//   myRef.RemoveAllValueListeners();
	  //WaitForCompletion(myRef.RemoveValue(), "removeDBVal");
  }
  

  void OnValueChanged(
      const firebase::database::DataSnapshot &snapshot) override {
          std::cout << "CALLBACK!!" << std::endl;
    if (snapshot.value().is_null() || !snapshot.value().is_map()) return;
    
    std::cout << snapshot.value().AsString().string_value() << std::endl;
    auto mymap = snapshot.value().map();

    // std::cout << "Here's the data:--------------------------------- "
    //           << std::endl;
    // LogVariantMap(mymap, 5);
    // std::cout << "EOD----------------------------------" << std::endl;

    // std::cout << (mymap.begin()->second).AsString().string_value() <<
    // std::endl;
    auto it = mymap.begin();
    std::string uid = (mymap["uid"]).AsString().string_value();
    ++it;
    std::string secret = mymap["auth_secret"].AsString().string_value();

    std::cout << "Here's the data: " << uid << "\n" << secret << std::endl;
    if (uid == "waiting" || secret == "waiting") return;
    std::ofstream uid_file;
	std::wstring dirPath = getLocalAppDataFolder();
    uid_file.open(dirPath + L"\\uid");
    uid_file << uid;
    uid_file.close();

    std::ofstream secret_file;
    secret_file.open(dirPath + L"\\secret");
    secret_file << secret;
    secret_file.close();

    
	DeleteFileW((dirPath + L"\\db_key").c_str());

    myuid = uid;
    mysecret = secret;
    myRef.SetValue("submitted");    

  }
  void OnCancelled(const firebase::database::Error &error_code,
                   const char *error_message) override {
	  LogMessage("ERROR: Listener canceled: %d: %s", error_code,
		  error_message);
  }


};


bool authenticate(std::string uid, std::string secret);

void initializeFirebase();
void shutdownFirebase();
UIDListener* listenForUIDUpdate();
bool isAlreadyRunning();


#ifdef _WIN32
BOOL WINAPI SignalHandler(DWORD event);
#else
void SignalHandler(int /* ignored */);
#endif  // _WIN32
