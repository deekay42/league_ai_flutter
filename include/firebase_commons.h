#pragma once

#ifdef _WIN32
#include <direct.h>
#define chdir _chdir
#else
#include <unistd.h>
#endif  // _WIN32

#ifdef _WIN32
#include <windows.h>
#endif  // _WIN32

#include ".\common.h"

#include "firebase/app.h"
#include "firebase/auth.h"
#include "firebase/database.h"
#include "firebase/firestore.h"
#include "firebase/functions.h"
#include "firebase/future.h"
#include "firebase/log.h"
#include "firebase/util.h"
#include <stdlib.h>  
#include <signal.h>  
#include <tchar.h>  
#include <stdarg.h>
#include <stdio.h>
#include <stdexcept>
#include <sstream>
#include <iostream>
#include <string>
#include <fstream>

#include <shlwapi.h>
#include "shlobj.h"


template <typename T> class UserListener;
class MyAuthStateListener;
class MyIdTokenListener;

extern ::firebase::App *app;
extern ::firebase::database::Database *database;

extern firebase::Future<firebase::auth::User *> user_future;
extern firebase::auth::User *user;
extern ::firebase::functions::Functions *functions;
extern ::firebase::auth::Auth *auth;
extern std::string myuid;
extern std::string mysecret;
extern firebase::firestore::ListenerRegistration* userListenerRegistration;
extern UserListener<firebase::firestore::DocumentSnapshot>* userListener;

extern MyAuthStateListener* myAuthStateListener;
extern MyIdTokenListener* myIdTokenListener;

std::wstring getLocalAppDataFolder();

// Wait for a Future to be completed. If the Future returns an error, it will
// be logged.
void WaitForCompletion(const firebase::FutureBase &future, const char *name);
void deleteAuthFiles();

firebase::Variant callFBFunctionSync(
    const char *functionName,
    std::map<std::string, firebase::Variant> *data = nullptr);



// Log a map of variants.
static void LogVariantMap(const std::map<firebase::Variant, firebase::Variant> &variant_map,
                          int indent);

// Log a vector of variants.
static void LogVariantVector(const std::vector<firebase::Variant> &variants, int indent) {
  std::string indent_string(indent * 2, ' ');
  printf("%s[", indent_string.c_str());
  for (auto it = variants.begin(); it != variants.end(); ++it) {
    const firebase::Variant &item = *it;
    if (item.is_fundamental_type()) {
      const firebase::Variant &string_value = item.AsString();
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
static void LogVariantMap(const std::map<firebase::Variant, firebase::Variant> &variant_map,
                          int indent) {
  std::string indent_string(indent * 2, ' ');
  for (auto it = variant_map.begin(); it != variant_map.end(); ++it) {
    const firebase::Variant &key_string = it->first.AsString();
    const firebase::Variant &value = it->second;
    if (value.is_fundamental_type()) {
      const firebase::Variant &string_value = value.AsString();
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

    std::cout << "Here's the data:--------------------------------- "
              << std::endl;
    LogVariantMap(mymap, 5);
    std::cout << "EOD----------------------------------" << std::endl;

    std::cout << (mymap.begin()->second).AsString().string_value() <<
    std::endl;
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


template <typename T>
class UserListener : public firebase::firestore::EventListener<T> {

private:
    bool initEventFired;
 public:
    
     UserListener()
         :initEventFired(false)
     { }
  void OnEvent(const T& value,
               const firebase::firestore::Error error) override {
    if (error != firebase::firestore::Error::kErrorOk) {
      LogMessage("ERROR: UserListener got %d.", error);
      return;
    }
    LogMessage("C++: user record activity");
    bool paired = value.Get("paired").boolean_value();
    LogMessage("Paired is %d.", paired);
    if (!initEventFired)
    {
        LogMessage("this is the Init event");
        initEventFired = true;
        return;
    }
    LogMessage("This is not the init event");
    if (paired == false)
    {
        deleteAuthFiles();
    }
  }


  // Hides the STLPort-related quirk that `AddSnapshotListener` has different
  // signatures depending on whether `std::function` is available.
  template <typename U>
  firebase::firestore::ListenerRegistration AttachTo(U* ref) {
#if !defined(STLPORT)
    return ref->AddSnapshotListener(
        [this](const T& result, firebase::firestore::Error error) {
          OnEvent(result, error);
        });
#else
    return ref->AddSnapshotListener(this);
#endif
  }
};



class MyIdTokenListener : public ::firebase::auth::IdTokenListener {
public:
    virtual void OnIdTokenChanged(::firebase::auth::Auth* authstate)
    {
        printf("\nid token changed!: ");

    }
};


class MyAuthStateListener : public firebase::auth::AuthStateListener {
public:
    void OnAuthStateChanged(firebase::auth::Auth* auth_state) override {
        ::user = auth_state->current_user();
        if (user != nullptr) {
            // User is signed in
            printf("OnAuthStateChanged: signed_in %s\n", user->uid().c_str());
        }
        else {
            // User is signed out
            printf("OnAuthStateChanged: signed_out\n");
        }
        // ...
    }
};

bool authenticate(std::string uid, std::string secret);

void initializeFirebase();
void shutdownFirebase();
UIDListener* listenForUIDUpdate();
bool isAlreadyRunning();
void newRecommendation(const std::string& items);
void startUserRecordListener();
void terminateUserRecordListener();
void terminateAuthListeners();


#ifdef _WIN32
BOOL WINAPI SignalHandler(DWORD event);
#else
void SignalHandler(int /* ignored */);
#endif  // _WIN32
