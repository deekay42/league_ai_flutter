// Copyright 2018 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include <fstream>
#include <vector>

#ifdef _DEBUG
#undef _DEBUG
#include <Python.h>
#define _DEBUG
#else
#include <Python.h>
#endif
#include <inttypes.h>
#include <stdarg.h>
#include <algorithm>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <iostream>
#include <sstream>
#include <thread>
#include "firebase/app.h"
#include "firebase/auth.h"
#include "firebase/database.h"
#include "firebase/functions.h"
#include "firebase/future.h"
#include "firebase/log.h"
#include "firebase/util.h"
#include "firebase_commons.h"

#include <btnonce/btnonce_plugin.h>
#include <fbfunctions/fbfunctions_plugin.h>
#include <launchbrowser/launchbrowser_plugin.h>
#include "cython.h"
#include "flutter/flutter_window_controller.h"
#include <shlwapi.h>
#include "shlobj.h"

using ::firebase::Variant;

::firebase::App *app = nullptr;
::firebase::database::Database *database = nullptr;
::firebase::functions::Functions *functions = nullptr;
::firebase::auth::Auth *auth = nullptr;

std::string myuid = "";
std::string mysecret = "";

firebase::Future<firebase::functions::HttpsCallableResult> GetCustomToken(
    const std::string &uid, const std::string &secret);

// Include windows.h last, to minimize potential conflicts. The CreateWindow
// macro needs to be undefined because it prevents calling
// FlutterWindowController's method.
#include <windows.h>
#undef CreateWindow

namespace {

// Returns the path of the directory containing this executable, or an empty
// string if the directory cannot be found.
std::string GetExecutableDirectory() {
  char buffer[MAX_PATH];
  if (GetModuleFileName(nullptr, buffer, MAX_PATH) == 0) {
    std::cerr << "Couldn't locate executable" << std::endl;
    return "";
  }
  std::string executable_path(buffer);
  size_t last_separator_position = executable_path.find_last_of('\\');
  if (last_separator_position == std::string::npos) {
    std::cerr << "Unabled to find parent directory of " << executable_path
              << std::endl;
    return "";
  }
  return executable_path.substr(0, last_separator_position);
}

}  // namespace

static void LogVariantMap(const std::map<Variant, Variant> &variant_map,
                          int indent);

std::wstring getLocalAppDataFolder()
{
	wchar_t* localAppData = 0;
	SHGetKnownFolderPath(FOLDERID_LocalAppData, 0, NULL, &localAppData);

	std::wstringstream ss;
	ss << localAppData << "\\League IQ";
	CreateDirectoryW(ss.str().c_str(), NULL);
	CoTaskMemFree(static_cast<void*>(localAppData));
	return ss.str();
}

class MyAuthStateListener : public firebase::auth::AuthStateListener {
 public:
  void OnAuthStateChanged(firebase::auth::Auth *auth) override {
    ::user = auth->current_user();
    if (user != nullptr) {
      // User is signed in
      printf("OnAuthStateChanged: signed_in %s\n", user->uid().c_str());
    } else {
      // User is signed out
      printf("OnAuthStateChanged: signed_out\n");
    }
    // ...
  }
};

class UIDListener : public firebase::database::ValueListener {
 public:
  firebase::database::DatabaseReference myRef;

 public:
  UIDListener(firebase::database::DatabaseReference myRef) : myRef(myRef) {}
  ~UIDListener()
  {
	  printf("deleting listener now\n");
	  printf("Removing value!\n");
	  myRef.RemoveAllValueListeners();
	  WaitForCompletion(myRef.RemoveValue(), "removeDBVal");
  }
  

  void OnValueChanged(
      const firebase::database::DataSnapshot &snapshot) override {
    if (snapshot.value().is_null()) return;
    std::cout << "CALLBACK!!" << std::endl;
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
  }
  void OnCancelled(const firebase::database::Error &error_code,
                   const char *error_message) override {
	  LogMessage("ERROR: Listener canceled: %d: %s", error_code,
		  error_message);
  }


};

// Log a vector of variants.
static void LogVariantVector(const std::vector<Variant> &variants, int indent) {
  std::string indent_string(indent * 2, ' ');
  printf("%s[", indent_string.c_str());
  for (auto it = variants.begin(); it != variants.end(); ++it) {
    const Variant &item = *it;
    if (item.is_fundamental_type()) {
      const Variant &string_value = item.AsString();
      printf("%s  %s,", indent_string.c_str(), string_value.string_value());
    } else if (item.is_vector()) {
      LogVariantVector(item.vector(), indent + 2);
    } else if (item.is_map()) {
      LogVariantMap(item.map(), indent + 2);
    } else {
      printf("%s  ERROR: unknown type %d", indent_string.c_str(),
             static_cast<int>(item.type()));
    }
  }
  printf("%s]", indent_string.c_str());
}

// Log a map of variants.
static void LogVariantMap(const std::map<Variant, Variant> &variant_map,
                          int indent) {
  std::string indent_string(indent * 2, ' ');
  for (auto it = variant_map.begin(); it != variant_map.end(); ++it) {
    const Variant &key_string = it->first.AsString();
    const Variant &value = it->second;
    if (value.is_fundamental_type()) {
      const Variant &string_value = value.AsString();
      printf("%s%s: %s,", indent_string.c_str(), key_string.string_value(),
             string_value.string_value());
    } else {
      printf("%s%s:", indent_string.c_str(), key_string.string_value());
      if (value.is_vector()) {
        LogVariantVector(value.vector(), indent + 1);
      } else if (value.is_map()) {
        LogVariantMap(value.map(), indent + 1);
      } else {
        printf("%s  ERROR: unknown type %d", indent_string.c_str(),
               static_cast<int>(value.type()));
      }
    }
  }
}

std::string readFile(std::string filename) {
  std::ifstream file(filename);
  std::string str;
  std::string file_contents;
  while (std::getline(file, str)) {
    file_contents += str;
    file_contents.push_back('\n');
  }
  return file_contents;
}

UIDListener* listenForUIDUpdate() {
  std::cout << "Hello1" << std::endl;

  firebase::database::DatabaseReference myRef =
      database->GetReference().Child("uids");
  
  std::string key =
      myRef.PushChild()
          .key();  // this returns the unique key generated by firebase
  std::cout << "key is " << key << std::endl;
  std::ofstream myfile;
  std::wstring dirPath = getLocalAppDataFolder();
  myfile.open(dirPath + L"\\db_key");
  myfile << key;
  myfile.close();
  std::cout << "Now setting data" << std::endl;
  myRef.Child(key).Child("uid").SetValue(
      "waiting");  // this creates the reqs key-value pair
  std::cout << "Data is now set" << std::endl;

  UIDListener *listener = new UIDListener(myRef.Child(key));
  myRef.Child(key).AddValueListener(listener);
  return listener;
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
  arguments.push_back("--disable-dart-asserts");
#endif
  flutter::FlutterWindowController flutter_controller(
      icu_data_path);

  // Start the engine.
  if (!flutter_controller.CreateWindow(500, 800, "League IQ", assets_path, arguments)) {
    return EXIT_FAILURE;
  }
  HWND flutterWindow = GetActiveWindow();

  RECT myrect = {NULL};
  if (GetWindowRect(flutterWindow, &myrect)) {
    ::SetWindowPos(flutterWindow, 0, myrect.left, 0, 500, 800,
                   SWP_NOOWNERZORDER | SWP_NOZORDER);
  } else
    ::SetWindowPos(flutterWindow, 0, 0, 0, 500, 800,
                   SWP_NOOWNERZORDER | SWP_NOZORDER | SWP_NOMOVE);

  BTNonceRegisterWithRegistrar(
      flutter_controller.GetRegistrarForPlugin("BTNonce"));
  FBFunctionsRegisterWithRegistrar(
      flutter_controller.GetRegistrarForPlugin("FBFunctions"));
  LaunchBrowserRegisterWithRegistrar(
      flutter_controller.GetRegistrarForPlugin("LaunchBrowser"));

  // Run until the window is closed.
  flutter_controller.RunEventLoop();
  return EXIT_SUCCESS;
}

void WaitForCompletion(const firebase::FutureBase &future, const char *name) {
  while (future.status() == firebase::kFutureStatusPending) {
    ProcessEvents(100);
  }
}

void initializeFirebase() {
  std::string init_file_contents = readFile("google-services.json");
  firebase::AppOptions *appOptions =
      firebase::AppOptions::LoadFromJsonConfig(init_file_contents.c_str());
  app = firebase::App::Create(*appOptions);

  LogMessage("Initialized Firebase App.");

  LogMessage("Initializing Firebase Auth and Cloud Functions.");

  // Use ModuleInitializer to initialize both Auth and Functions, ensuring no
  // dependencies are missing.
  void *initialize_targets[] = {&auth, &functions, &database};

  const firebase::ModuleInitializer::InitializerFn initializers[] = {
      [](::firebase::App *app, void *data) {
        LogMessage("Attempt to initialize Firebase Auth.");
        void **targets = reinterpret_cast<void **>(data);
        ::firebase::InitResult result;
        *reinterpret_cast<::firebase::auth::Auth **>(targets[0]) =
            ::firebase::auth::Auth::GetAuth(app, &result);
        return result;
      },
      [](::firebase::App *app, void *data) {
        LogMessage("Attempt to initialize Cloud Functions.");
        void **targets = reinterpret_cast<void **>(data);
        ::firebase::InitResult result;
        *reinterpret_cast<::firebase::functions::Functions **>(targets[1]) =
            ::firebase::functions::Functions::GetInstance(app, &result);
        return result;
      },
      [](::firebase::App *app, void *data) {
        LogMessage("Attempt to initialize Realtime Database");
        void **targets = reinterpret_cast<void **>(data);
        ::firebase::InitResult result;
        *reinterpret_cast<::firebase::database::Database **>(targets[2]) =
            ::firebase::database::Database::GetInstance(app, &result);
        return result;
      }};

  ::firebase::ModuleInitializer initializer;
  initializer.Initialize(app, initialize_targets, initializers,
                         sizeof(initializers) / sizeof(initializers[0]));

  WaitForCompletion(initializer.InitializeLastResult(), "Initialize");

  if (initializer.InitializeLastResult().error() != 0) {
    LogMessage("Failed to initialize Firebase libraries: %s",
               initializer.InitializeLastResult().error_message());
    ProcessEvents(2000);
  }
  LogMessage(
      "Successfully initialized Firebase Auth, Cloud Functions and Realtime "
      "Database.");

  // To test against a local emulator, uncomment this line:
  //   functions->UseFunctionsEmulator("http://localhost:5005");
  // Or when running in an Android emulator:
  //   functions->UseFunctionsEmulator("http://10.0.2.2:5005");
}

void shutdownFirebase() {

	LogMessage("Shutting down the Functions library.");
	delete functions;
	functions = nullptr;

	LogMessage("Shutting down the DB library.");
	delete database;
	database = nullptr;

	LogMessage("Signing out from account.");
	auth->SignOut();
	LogMessage("Shutting down the Auth library.");
	delete auth;
	auth = nullptr;

	LogMessage("Shutting down Firebase App.");
	delete app;
}

extern "C" int common_main(int argc, const char *argv[]) {


  std::wstring dirPath = getLocalAppDataFolder();
  DeleteFileW((dirPath + L"\\ai_loaded").c_str());
  std::remove("ai_loaded");
  printf("Now running python code\n");
  std::thread pythonThread(runCythonCode);
  printf("Python code kickced off\n");
  initializeFirebase();
  
  std::ifstream file_uid(dirPath + L"\\uid");
  std::ifstream file_secret(dirPath + L"\\secret");
  UIDListener *listener = nullptr;
  if (!file_uid || !file_secret) {
	  listener = listenForUIDUpdate();
	  
  } else {
    std::getline(file_uid, myuid);
    std::getline(file_secret, mysecret);
  }

  std::cout << "now runnning flutter" << std::endl;
  runFlutterCode();
  std::cout << "runnning flutter complete" << std::endl;

  if (listener)
  {
	  delete listener;
	  listener = nullptr;
  }	
  shutdownFirebase();

  // Wait until the user wants to quit the app.
  while (!ProcessEvents(1000)) {
  }

  return 0;
}

/*

int main(int argc, char **argv) {
  firebase::functions::HttpsCallableReference lol = initFirebase();
  auto mylol = lol.Call();
  std::cout << "firebase inited" << std::endl;
  MyAuthStateListener state_change_listener;
  auth->AddAuthStateListener(&state_change_listener);

  std::ifstream file_uid("uid");
  std::ifstream file_secret("secret");
  if (!file_uid || !file_secret) {
    listenForUIDUpdate();
  } else {
    std::string uid;
    std::string secret;
    std::getline(file_uid, uid);
    std::getline(file_secret, secret);
    std::cout << "got the uid and the secret:" << uid << " " << secret
              << std::endl;
    auto future = GetCustomToken(uid, secret);
    std::cout << "getcustomtoken complete" << std::endl;
    future.OnCompletion(OnTokenCompleteCallback);
    std::cout << "oncompletiong complete" << std::endl;
  }

  


}
*/