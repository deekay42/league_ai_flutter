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
#include "fbfunctions/fbfunctions_plugin.h"

#include <json/json.h>
#include <exception>
#include <iostream>
#include <memory>
#include <vector>
#include <time.h>
#include <stdexcept> 

#include <flutter/json_method_codec.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar.h>

#include "firebase/app.h"
#include "firebase/functions.h"

#include "firebase_commons.h"

// File chooser callback results.
static constexpr int kCancelResultValue = 0;
static constexpr int kOkResultValue = 1;

const char kChannelName[] = "flutter/fbfunctions";

namespace plugins_fbfunctions {

class FBFunctionsPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(
      flutter::PluginRegistrar *registrar);

  virtual ~FBFunctionsPlugin();

 private:
  // Creates a plugin that communicates on the given channel.
  FBFunctionsPlugin(
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

static Json::Value CreateResponseObject(
    const firebase::Variant &fbf_return_val) {
  if (fbf_return_val.is_null()) {
    return Json::Value();
  }
  if (fbf_return_val.is_map()) {
    Json::Value response;
    const auto mymap = fbf_return_val.map();

    for (auto it = mymap.begin(); it != mymap.end(); ++it) {
      if (!it->first.is_string()) {
        std::cerr << "function return map must use string keys\n";
        throw std::runtime_error("function return map must use string keys\n");
      }
      std::string key = it->first.string_value();
      auto val = it->second;

      if (val.is_string())
        response[key] = (val.string_value());
      else if (val.is_bool())
        response[key] = (val.bool_value());
      else if (val.is_double())
        response[key] = (val.double_value());
      else if (val.is_int64())
        response[key] = (val.int64_value());
      else if (val.is_null())
        response[key] = (nullptr);
      else {
        std::cerr << "function return type must be scalar type\n";
        throw std::runtime_error("function return type must be scalar type\n");
      }
    }
    return response;

  } else if (fbf_return_val.is_container_type()) {
    std::cerr << "function return type must be scalar type\n";
    throw std::runtime_error("function return type must be scalar type\n");
  }
  Json::Value response(Json::arrayValue);
  // for (const firebase::Variant &filename : filenames) {
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
    flutter::PluginRegistrar *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<Json::Value>>(
          registrar->messenger(), kChannelName,
          &flutter::JsonMethodCodec::GetInstance());
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
    std::unique_ptr<flutter::MethodChannel<Json::Value>>
        channel)
    : channel_(std::move(channel)) {}

FBFunctionsPlugin::~FBFunctionsPlugin() {}

// void OnFBCallback(
//     const firebase::Future<firebase::functions::HttpsCallableResult>& future,
//     void* result_cb) {
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
//   // This will assert if the result returned from the function wasn't a
//   string. std::string message = data.string_value(); std::vector<std::string>
//   return_result; return_result.push_back(message);

//   auto result_cb_typed =
//       static_cast<flutter_desktop_embedding::MethodResult<Json::Value> *>(
//           result_cb);

//   Json::Value response_object(CreateResponseObject(return_result));

//   result_cb_typed->Success(&response_object);
//   // Display the result in the UI.
//   printf(message.c_str());
// }

// firebase::Future<firebase::functions::HttpsCallableResult>
// CallFBFunction(const std::string name,
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



void FBFunctionsPlugin::HandleMethodCall(
    const flutter::MethodCall<Json::Value> &method_call,
    std::unique_ptr<flutter::MethodResult<Json::Value>> result) {
  if (!method_call.arguments() || method_call.arguments()->isNull()) {
    result->Error("Bad Arguments", "Null file chooser method args received");
    return;
  }
  firebase::Variant variant_result;
  const Json::Value &args = *method_call.arguments();
  if (args["methodName"] == "authenticate") {
	  if (myuid == "" || mysecret == "")
	  {
		  //ugly, but using result->Error apparently creates uncatchable exceptions.
		  Json::Value response_object(CreateResponseObject(firebase::Variant("files_missing")));
		  result->Success(&response_object);
		  return;
	  }
	  
	  bool signInResult = authenticate(myuid, mysecret);
	  variant_result = firebase::Variant(signInResult ? "successful" : "unsuccessful");;
  } else {
	  firebase::auth::User* user = auth->current_user();
	  if (user != nullptr) {
		  firebase::Future<std::string> idToken = user->GetToken(true);
		  WaitForCompletion(idToken, "idToken");
		  // Send token to your backend via HTTPS
		  // ...
	  }
	  else
	  {
		  printf("User is NULL\n");
	  }
    std::map<std::string, firebase::Variant> data;
    auto members = args.getMemberNames();
    for (auto it = members.begin(); it != members.end(); ++it)
      data[*it] = firebase::Variant(args[*it].asString());
    variant_result =
        callFBFunctionSync(args["methodName"].asString().c_str(), &data);
  }

  Json::Value response_object(CreateResponseObject(variant_result));
  result->Success(&response_object);

  // auto future = CallFBFunction(args["methodName"].asString(), args);
  // future.OnCompletion(OnFBCallback, result_cb.get());
}

}  // namespace plugins_fbfunctions

void FBFunctionsRegisterWithRegistrar(
	FlutterDesktopPluginRegistrarRef  registrar) {
  // The plugin registrar owns the plugin, registered callbacks, etc., so must
  // remain valid for the life of the application.
  static auto *plugin_registrar =
      new flutter::PluginRegistrar(registrar);
  plugins_fbfunctions::FBFunctionsPlugin::RegisterWithRegistrar(
      plugin_registrar);
}
