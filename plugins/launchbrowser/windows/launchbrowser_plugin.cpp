// Copyright 2019 Google LLC
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
#include "include/launchbrowser/launchbrowser_plugin.h"

// windows.h must be imported before VersionHelpers.h or it will break
// compilation.
#include <windows.h>

#include <VersionHelpers.h>
#include <flutter/flutter_view.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <flutter_windows.h>

#include <codecvt>
#include <memory>
#include <sstream>
#include <atlbase.h>    

namespace {

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

// See window_size_channel.dart for documentation.
const char kChannelName[] = "flutter/launchbrowser";



class LaunchbrowserPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  // Creates a plugin that communicates on the given channel.
  LaunchbrowserPlugin(flutter::PluginRegistrarWindows *registrar);

  virtual ~LaunchbrowserPlugin();

 private:
  // Called when a method is called on the plugin channel;
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // The registrar for this plugin, for accessing the window.
  flutter::PluginRegistrarWindows *registrar_;
};

// static
void LaunchbrowserPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), kChannelName,
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<LaunchbrowserPlugin>(registrar);

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

LaunchbrowserPlugin::LaunchbrowserPlugin(flutter::PluginRegistrarWindows *registrar)
    : registrar_(registrar) {}

LaunchbrowserPlugin::~LaunchbrowserPlugin(){};

void LaunchbrowserPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
   if (method_call.method_name().compare("launchbrowser") == 0) {
    if (!method_call.arguments() || !method_call.arguments()->IsString()) {
      result->Error("Bad arguments", "Expected string");
      return;
    }
        LPCSTR url = method_call.arguments()->StringValue().c_str();
        ShellExecuteA(NULL, "open", url, NULL, NULL, SW_SHOWNORMAL);
        
        result->Success();
        
  } else {
    result->NotImplemented();
  }
}

}  // namespace

void LaunchbrowserPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  LaunchbrowserPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
