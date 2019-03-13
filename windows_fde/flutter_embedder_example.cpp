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
#include <iostream>
#include <string>
#include <vector>

#include <Python.h>
#include <thread>

#include "firebase/app.h"
#include "firebase/database.h"

#include "flutter_desktop_embedding/flutter_window_controller.h"

using namespace firebase;

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

class UIDListener : public firebase::database::ValueListener {
 public:
  void OnValueChanged(
      const firebase::database::DataSnapshot &snapshot) override {
    if (snapshot.value().is_null()) return;
    std::cout << "CALLBACK!!" << std::endl;
    auto mymap = snapshot.value().map();

    std::cout << "Here's the data:--------------------------------- "
              << std::endl;
    LogVariantMap(mymap, 5);
    std::cout << "EOD----------------------------------" << std::endl;

    std::cout << (mymap.begin()->second).AsString().string_value() << std::endl;
    std::string uid = (mymap.begin()->second).AsString().string_value();
    
    std::cout << "Here's the data: " << uid << std::endl;
    if (uid == "waiting") return;
	std::ofstream myfile;
    myfile.open("uid");
    myfile << uid;
    myfile.close();
    // Do something with the data in snapshot...
  }
  void OnCancelled(const firebase::database::Error &error_code,
                   const char *error_message) override {
    std::cout << "LOL" << std::endl;
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

void listenForUIDUpdate() {
  std::cout << "Hello1" << std::endl;
  std::ifstream file("google-services.json");
  std::string str;
  std::string file_contents;
  while (std::getline(file, str)) {
    file_contents += str;
    file_contents.push_back('\n');
  }
  std::cout << "Hello2" << std::endl;
  ::firebase::AppOptions *appOptions =
      ::firebase::AppOptions::LoadFromJsonConfig(file_contents.c_str());
  // firebase::App *app = firebase::App::GetInstance();
  firebase::App *app = ::firebase::App::Create(*appOptions);
  ::firebase::database::Database *database =
      ::firebase::database::Database::GetInstance(app);

  firebase::database::DatabaseReference myRef =
      database->GetReference().Child("uids");

  std::string key =
      myRef.PushChild()
          .key();  // this returns the unique key generated by firebase
  std::cout << "key is " << key << std::endl;
  std::ofstream myfile;
  myfile.open("db_key");
  myfile << key;
  myfile.close();
  std::cout << "Now setting data" << std::endl;
  myRef.Child(key)
      .Child("uid")
      .SetValue("waiting");  // this creates the reqs key-value pair
  std::cout << "Data is now set" << std::endl;

  UIDListener *listener = new UIDListener();
  // firebase::Future<firebase::database::DataSnapshot> result =
  myRef.Child(key).AddValueListener(listener);
}

void runPythonCode() {
  Py_Initialize();
  PyRun_SimpleString(
      "import "
      "sys\nsys.path.append(r\"C:\\Users\\Dom\\code\\flutter-desktop-"
      "embedding\\example\\windows_fde\")\n");

  PyRun_SimpleString("print('Python search path %s' % sys.path)");
  PyObject *obj = Py_BuildValue("s", "screenshot.py");
  FILE *file = _Py_fopen_obj(obj, "r+");
  if (file != NULL) {
    PyRun_SimpleFile(file, "screenshot.py");
  }
  Py_FinalizeEx();
}

int runFlutterCode() {
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
  flutter_desktop_embedding::FlutterWindowController flutter_controller(
      icu_data_path);

  // Start the engine.
  if (!flutter_controller.CreateWindow(480, 640, assets_path, arguments)) {
    return EXIT_FAILURE;
  }

  // Run until the window is closed.
  flutter_controller.RunEventLoop();
  return EXIT_SUCCESS;
}

int main(int argc, char **argv) {
  std::ifstream file("uid");
  if (!file) {
    listenForUIDUpdate();
  }
  
  // std::thread pythonThread(runPythonCode);
  // Resources are located relative to the executable.
  return runFlutterCode();
  //std::string lol;
  //std::cin >> lol;
  //return 0;
}
