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

#include <json/json.h>
#include <iostream>
#include <memory>
#include <vector>
#include <exception>

#include <flutter/json_method_codec.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar.h>

#include "launchbrowser/launchbrowser_plugin.h"

#include <windows.h>

const char kChannelName[] = "flutter/launchbrowser";

namespace plugins_launchbrowser {

class LaunchBrowserPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(
      flutter::PluginRegistrar *registrar);

  virtual ~LaunchBrowserPlugin();

 private:
  // Creates a plugin that communicates on the given channel.
  LaunchBrowserPlugin(
      std::unique_ptr<flutter::MethodChannel<Json::Value>>
          channel);

  // Called when a method is called on |channel_|;
  void HandleMethodCall(
      const flutter::MethodCall<Json::Value> &method_call,
      std::unique_ptr<flutter::MethodResult<Json::Value>>
          result);

  // The MethodChannel used for communication with the Flutter engine.
  std::unique_ptr<flutter::MethodChannel<Json::Value>>
      channel_;
};


// static
void LaunchBrowserPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrar *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<Json::Value>>(
          registrar->messenger(), kChannelName,
          &flutter::JsonMethodCodec::GetInstance());
  auto *channel_pointer = channel.get();

  // Uses new instead of make_unique due to private constructor.
  std::unique_ptr<LaunchBrowserPlugin> plugin(
      new LaunchBrowserPlugin(std::move(channel)));

  channel_pointer->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });
  registrar->EnableInputBlockingForChannel(kChannelName);

  registrar->AddPlugin(std::move(plugin));
}

LaunchBrowserPlugin::LaunchBrowserPlugin(
    std::unique_ptr<flutter::MethodChannel<Json::Value>>
        channel)
    : channel_(std::move(channel)) {}

LaunchBrowserPlugin::~LaunchBrowserPlugin() {}


void LaunchBrowserPlugin::HandleMethodCall(
    const flutter::MethodCall<Json::Value> &method_call,
    std::unique_ptr<flutter::MethodResult<Json::Value>>
        result)
{
  if (!method_call.arguments() || method_call.arguments()->isNull()) {
    result->Error("Bad Arguments", "Null file chooser method args received");
    return;
  }

  const Json::Value &args = *method_call.arguments();
  LPCSTR url = args["url"].asCString();
  ShellExecute(0, 0, url, 0, 0, SW_SHOW); 
  
  result->Success(&Json::Value());
}

}  // namespace plugins_file_chooser

void LaunchBrowserRegisterWithRegistrar(
	FlutterDesktopPluginRegistrarRef  registrar) {
  // The plugin registrar owns the plugin, registered callbacks, etc., so must
  // remain valid for the life of the application.
  static auto *plugin_registrar =
      new flutter::PluginRegistrar(registrar);
  plugins_launchbrowser::LaunchBrowserPlugin::RegisterWithRegistrar(
      plugin_registrar);
}
