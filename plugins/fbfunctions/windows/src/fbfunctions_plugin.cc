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
#include "plugins/fbfunctions/windows/include/fbfunctions/fbfunctions_plugin.h"

#include <json/json.h>
#include <iostream>
#include <memory>
#include <vector>
#include <exception>

#include <flutter_desktop_embedding/json_method_codec.h>
#include <flutter_desktop_embedding/method_channel.h>
#include <flutter_desktop_embedding/plugin_registrar.h>

#include "plugins/fbfunctions/common/channel_constants.h"

#include "firebase/app.h"
#include "firebase/functions.h"

#include "firebase_commons.h"


// File chooser callback results.
static constexpr int kCancelResultValue = 0;
static constexpr int kOkResultValue = 1;

namespace plugins_fbfunctions {

class FBFunctionsPlugin : public flutter_desktop_embedding::Plugin {
 public:
  static void RegisterWithRegistrar(
      flutter_desktop_embedding::PluginRegistrar *registrar);

  virtual ~FBFunctionsPlugin();

 private:
  // Creates a plugin that communicates on the given channel.
  FBFunctionsPlugin(
      std::unique_ptr<flutter_desktop_embedding::MethodChannel<Json::Value>>
          channel);

  // Called when a method is called on |channel_|;
  void HandleMethodCall(
      const flutter_desktop_embedding::MethodCall<Json::Value> &method_call,
      std::unique_ptr<flutter_desktop_embedding::MethodResult<Json::Value>>
          result);

  // The MethodChannel used for communication with the Flutter engine.
  std::unique_ptr<flutter_desktop_embedding::MethodChannel<Json::Value>>
      channel_;
};

static Json::Value CreateResponseObject(
    const firebase::Variant &fbf_return_val) {
  if (fbf_return_val.is_null()) {
    return Json::Value();
  }
  if (fbf_return_val.is_container_type()) {
    std::cerr << "function return type must be scalar type\n";
    throw std::runtime_error("function return type must be scalar type\n");
	}
  Json::Value response(Json::arrayValue);
  //for (const firebase::Variant &filename : filenames) {
	if (fbf_return_val.is_string())
		response.append(fbf_return_val.string_value());
    else if (fbf_return_val.is_bool())
        response.append(fbf_return_val.bool_value());
    else if (fbf_return_val.is_double())
        response.append(fbf_return_val.double_value());
    else if (fbf_return_val.is_int64())
        response.append(fbf_return_val.int64_value());
    else if (fbf_return_val.is_null())
      response.append(nullptr);
  return response;
}

// static
void FBFunctionsPlugin::RegisterWithRegistrar(
    flutter_desktop_embedding::PluginRegistrar *registrar) {
  auto channel =
      std::make_unique<flutter_desktop_embedding::MethodChannel<Json::Value>>(
          registrar->messenger(), kChannelName,
          &flutter_desktop_embedding::JsonMethodCodec::GetInstance());
  auto *channel_pointer = channel.get();

  // Uses new instead of make_unique due to private constructor.
  std::unique_ptr<FBFunctionsPlugin> plugin(
      new FBFunctionsPlugin(std::move(channel)));

  channel_pointer->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });
  registrar->EnableInputBlockingForChannel(kChannelName);

  registrar->AddPlugin(std::move(plugin));
}

FBFunctionsPlugin::FBFunctionsPlugin(
    std::unique_ptr<flutter_desktop_embedding::MethodChannel<Json::Value>>
        channel)
    : channel_(std::move(channel)) {}

FBFunctionsPlugin::~FBFunctionsPlugin() {}

// void OnFBCallback(
//     const firebase::Future<firebase::functions::HttpsCallableResult>& future, void* result_cb) {
//   if (future.error() != firebase::functions::kErrorNone) {
//     // Function error code, will be kErrorInternal if the failure was not
//     // handled properly in the function call.
//     auto code = static_cast<firebase::functions::Error>(future.error());

//     // Display the error in the UI.
//     std::cerr << future.error_message() << std::endl;
//     return;
//   }

//   const firebase::functions::HttpsCallableResult *result = future.result();
//   firebase::Variant data = result->data();
//   // This will assert if the result returned from the function wasn't a string.
//   std::string message = data.string_value();
//   std::vector<std::string> return_result;
//   return_result.push_back(message);

//   auto result_cb_typed =
//       static_cast<flutter_desktop_embedding::MethodResult<Json::Value> *>(
//           result_cb);

//   Json::Value response_object(CreateResponseObject(return_result));
  
//   result_cb_typed->Success(&response_object);
//   // Display the result in the UI.
//   printf(message.c_str());
// }

// firebase::Future<firebase::functions::HttpsCallableResult> CallFBFunction(const std::string name,
//     const Json::Value &args) {

 
//   // Create the arguments to the callable function.
//   firebase::Variant data = firebase::Variant::EmptyMap();
//   auto members = args.getMemberNames();
//   for(auto it = members.begin(); it!=members.end(); ++it)
//     data.map()[*it] = firebase::Variant(args[*it].asString());

//   // Call the function and add a callback for the result.
//   firebase::functions::HttpsCallableReference doSomething =
//       functions->GetHttpsCallable(name.c_str());
//   return doSomething.Call(data);
// }

bool signIn(std::string custom_token) {
  firebase::Future<firebase::auth::User *> sign_in_future =
      auth->SignInWithCustomToken(custom_token.c_str());
  WaitForCompletion(sign_in_future, "SignIn");
  if (sign_in_future.error() == firebase::auth::kAuthErrorNone) {
    LogMessage("Auth: Signed in as user!");
    return true;
  } else {
    LogMessage("ERROR: Could not sign in anonymously. Error %d: %s",
               sign_in_future.error(), sign_in_future.error_message());
    return false;
  }
}

void FBFunctionsPlugin::HandleMethodCall(
    const flutter_desktop_embedding::MethodCall<Json::Value> &method_call,
    std::unique_ptr<flutter_desktop_embedding::MethodResult<Json::Value>>
        result)
{
  if (!method_call.arguments() || method_call.arguments()->isNull()) {
    result->Error("Bad Arguments", "Null file chooser method args received");
    return;
  }
  firebase::Variant variant_result;
  const Json::Value &args = *method_call.arguments();
  if(args["methodName"] == "authenticate")
  {
    LogMessage("Trying to auth user!");
    
  std::map<std::string, firebase::Variant> data;
  data["uid"] = firebase::Variant(myuid);
  data["auth_secret"] = firebase::Variant(mysecret);
    std::string customToken;
    customToken = callFBFunctionSync("getCustomToken", &data).string_value();
    variant_result = firebase::Variant(signIn(customToken));
  }
  else
  {
    std::map<std::string, firebase::Variant> data;
    auto members = args.getMemberNames();
    for(auto it = members.begin(); it!=members.end(); ++it)
      data[*it] = firebase::Variant(args[*it].asString());
    variant_result =
        callFBFunctionSync(args["methodName"].asString().c_str(), &data);
  }

  
  
  Json::Value response_object(CreateResponseObject(variant_result));
  result->Success(&response_object);

  //auto future = CallFBFunction(args["methodName"].asString(), args);
  //future.OnCompletion(OnFBCallback, result_cb.get());
    std::cout << "after future call" << std::endl;
  
}

}  // namespace plugins_file_chooser

void FBFunctionsRegisterWithRegistrar(
    FlutterEmbedderPluginRegistrarRef registrar) {
  // The plugin registrar owns the plugin, registered callbacks, etc., so must
  // remain valid for the life of the application.
  static auto *plugin_registrar =
      new flutter_desktop_embedding::PluginRegistrar(registrar);
  plugins_fbfunctions::FBFunctionsPlugin::RegisterWithRegistrar(
      plugin_registrar);
}
