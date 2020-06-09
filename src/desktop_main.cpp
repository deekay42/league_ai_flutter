// Copyright 2016 Google Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include <signal.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdexcept>
#include <sstream>


#include "firebase/app.h"
#include "firebase/auth.h"
#include "firebase/database.h"
#include "firebase/functions.h"
#include "firebase/future.h"
#include "firebase/log.h"
#include "firebase/util.h"
#include "firebase_commons.h"

#include <shlwapi.h>
#include "shlobj.h"
#include <iostream>
#include <fstream>

#include <windows.h>

#ifdef _WIN32
#include <direct.h>
#define chdir _chdir
#else
#include <unistd.h>
#endif  // _WIN32

#ifdef _WIN32
#include <windows.h>
#endif  // _WIN32

#include <algorithm>
#include <string>

#include "firebase_commons.h"

// The TO_STRING macro is useful for command line defined strings as the quotes
// get stripped.
#define TO_STRING_EXPAND(X) #X
#define TO_STRING(X) TO_STRING_EXPAND(X)

// Path to the Firebase config file to load.
#ifdef FIREBASE_CONFIG
#define FIREBASE_CONFIG_STRING TO_STRING(FIREBASE_CONFIG)
#else
#define FIREBASE_CONFIG_STRING ""
#endif  // FIREBASE_CONFIG

//extern "C" int common_main();

static bool quit = false;



#ifdef _WIN32
BOOL WINAPI SignalHandler(DWORD event) {
	printf("in signalhandler1");
  if (!(event == CTRL_C_EVENT || event == CTRL_BREAK_EVENT)) {
    return FALSE;
  }
  quit = true;
  return TRUE;
}
#else
void SignalHandler(int /* ignored */) { printf("in signalhandler2");  quit = true; }
#endif  // _WIN32

bool ProcessEvents(int msec) {
#ifdef _WIN32
  Sleep(msec);
#else
  usleep(msec * 1000);
#endif  // _WIN32
  return quit;
}

using ::firebase::Variant;

::firebase::App *app = nullptr;
::firebase::database::Database *database = nullptr;
::firebase::functions::Functions *functions = nullptr;
::firebase::auth::Auth *auth = nullptr;
::firebase::auth::User* user = nullptr;

std::string myuid = "";
std::string mysecret = "";

firebase::Future<firebase::functions::HttpsCallableResult> GetCustomToken(
    const std::string &uid, const std::string &secret);


static void LogVariantMap(const std::map<Variant, Variant>& variant_map,
    int indent);


std::string PathForResource() {
  return std::string();
}

void LogMessage(const char* format, ...) {
  va_list list;
  va_start(list, format);
  vprintf(format, list);
  va_end(list);
  printf("\n");
  fflush(stdout);
}

class MyAuthStateListener : public firebase::auth::AuthStateListener {
 public:
  void OnAuthStateChanged(firebase::auth::Auth *auth_state) override {
    ::user = auth_state->current_user();
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


std::wstring getLocalAppDataFolder()
{
    wchar_t* localAppData = 0;
    SHGetKnownFolderPath(FOLDERID_LocalAppData, 0, NULL, &localAppData);

    std::wstringstream base, tess;
    base << localAppData << "\\League IQ";
    CreateDirectoryW(base.str().c_str(), NULL);
    tess << localAppData << "\\League IQ" << "\\tesseract";
    CreateDirectoryW(tess.str().c_str(), NULL);
    CoTaskMemFree(static_cast<void*>(localAppData));
    return base.str();
}





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

class MyIdTokenListener : public ::firebase::auth::IdTokenListener {
public:
	virtual void OnIdTokenChanged(::firebase::auth::Auth* authstate)
	{
		printf("\nid token changed!: ");
		
	}
};

bool signIn(std::string custom_token) {
	auth->AddAuthStateListener(new MyAuthStateListener());
	auth->AddIdTokenListener(new MyIdTokenListener());
	firebase::Future<firebase::auth::User *> sign_in_future =
		auth->SignInWithCustomToken(custom_token.c_str());
	WaitForCompletion(sign_in_future, "SignIn");
	if (sign_in_future.error() == firebase::auth::kAuthErrorNone) {
		LogMessage("Auth: Signed in as user!");
		return true;
	}
	else {
		LogMessage("ERROR: Could not sign in anonymously. Error %d: %s",
			sign_in_future.error(), sign_in_future.error_message());
		return false;
	}
}

bool authenticate(std::string uid, std::string secret)
{
    firebase::auth::User* currentuser = auth->current_user();
	if (currentuser != nullptr) {
		return true;
	}
	LogMessage("Trying to auth user!");
	if (uid == "" || secret == "")
	{
		LogMessage("ERROR: uid or secret are empty");
		throw std::invalid_argument("uid or secret are empty");
	}
	
	std::map<std::string, firebase::Variant> data;
	data["uid"] = firebase::Variant(uid);
	data["auth_secret"] = firebase::Variant(secret);
	firebase::Variant customToken;
	customToken = callFBFunctionSync("getCustomToken", &data);
	if (customToken.is_null())
		return false;
	return signIn(customToken.string_value());
}




firebase::Variant callFBFunctionSync(
    const char *functionName,
    std::map<std::string, firebase::Variant> *data) {
  firebase::Future<firebase::functions::HttpsCallableResult> future;
  // Create a callable.
  LogMessage("Calling function %s", functionName);
  firebase::functions::HttpsCallableReference caller;
  caller = functions->GetHttpsCallable(functionName);
  { future = data ? caller.Call(*data) : caller.Call(); }
  WaitForCompletion(future, "Call");
  firebase::Variant result;
  if (future.error() != firebase::functions::kErrorNone) {
    LogMessage("FAILED!");
    LogMessage("  Error %d: %s", future.error(), future.error_message());
	result = firebase::Variant::Null();
  } else {
    result = future.result()->data();

    // std::string result_string = result.string_value();
    // LogMessage("SUCCESS.");
    // LogMessage("  Got expected result: %s", result_string.c_str());
    
  }
  return result;
}

// Change the current working directory to the directory containing the
// specified file.
void ChangeToFileDirectory(const char* file_path) {
  std::string path(file_path);
  std::replace(path.begin(), path.end(), '\\', '/');
  auto slash = path.rfind('/');
  if (slash != std::string::npos) {
    std::string directory = path.substr(0, slash);
    if (!directory.empty()) chdir(directory.c_str());
  }
}

bool isAlreadyRunning()
{
	HANDLE m_singleInstanceMutex = CreateMutex(NULL, TRUE, L"ONLY_ONE_INSTACE_ALLOWED");
	if (m_singleInstanceMutex == NULL || GetLastError() == ERROR_ALREADY_EXISTS) {
		HWND existingApp = FindWindow(0, L"League IQ");
		if (existingApp) SetForegroundWindow(existingApp);
		ReleaseMutex(m_singleInstanceMutex);
		return true; // Exit the app. For MFC, return false from InitInstance.
	}
	ReleaseMutex(m_singleInstanceMutex);
	return false;
}


#if defined(_WIN32)
// Returns the number of microseconds since the epoch.
int64_t WinGetCurrentTimeInMicroseconds() {
  FILETIME file_time;
  GetSystemTimeAsFileTime(&file_time);

  ULARGE_INTEGER now;
  now.LowPart = file_time.dwLowDateTime;
  now.HighPart = file_time.dwHighDateTime;

  // Windows file time is expressed in 100s of nanoseconds.
  // To convert to microseconds, multiply x10.
  return now.QuadPart * 10LL;
}
#endif



void WaitForCompletion(const firebase::FutureBase &future, const char *name) {
  while (future.status() == firebase::kFutureStatusPending) {
    ProcessEvents(100);
  }
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
  std::cout << "db url1: " << std::endl;
  std::cout << database->url() << std::endl;

  std::cout << (void*)database << std::endl;

  UIDListener *listener = new UIDListener(myRef.Child(key));
  myRef.Child(key).AddValueListener(listener);
  return listener;
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
      [](::firebase::App *myapp, void *data) {
        LogMessage("Attempt to initialize Firebase Auth.");
        void **targets = reinterpret_cast<void **>(data);
        ::firebase::InitResult result;
        *reinterpret_cast<::firebase::auth::Auth **>(targets[0]) =
            ::firebase::auth::Auth::GetAuth(myapp, &result);
        return result;
      },
      [](::firebase::App * myapp, void *data) {
        LogMessage("Attempt to initialize Cloud Functions.");
        void **targets = reinterpret_cast<void **>(data);
        ::firebase::InitResult result;
        *reinterpret_cast<::firebase::functions::Functions **>(targets[1]) =
            ::firebase::functions::Functions::GetInstance(myapp, &result);
        return result;
      },
      [](::firebase::App * myapp, void *data) {
        LogMessage("Attempt to initialize Realtime Database");
        void **targets = reinterpret_cast<void **>(data);
        ::firebase::InitResult result;
        *reinterpret_cast<::firebase::database::Database **>(targets[2]) =
            ::firebase::database::Database::GetInstance(myapp, &result);
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