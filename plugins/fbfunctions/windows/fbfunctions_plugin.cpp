#include "fbfunctions_plugin.h"

#include <firebase_commons.h>
// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>



#include <map>
#include <memory>
#include <sstream>

namespace {

class FbfunctionsPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FbfunctionsPlugin();

  virtual ~FbfunctionsPlugin();

 private:
  UIDListener* listener = nullptr;
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

// static
void FbfunctionsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "fbfunctions",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<FbfunctionsPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

FbfunctionsPlugin::FbfunctionsPlugin() 
{
    initializeFirebase();
    std::wstring dirPath = getLocalAppDataFolder();
    std::ifstream file_uid(dirPath + L"\\uid");
    std::ifstream file_secret(dirPath + L"\\secret");
    
    if (!file_uid || !file_secret) {
        auth->SignOut();
        listener = listenForUIDUpdate();

    }
    else {
        std::getline(file_uid, myuid);
        std::getline(file_secret, mysecret);
    }
    
}

FbfunctionsPlugin::~FbfunctionsPlugin() 
{
    shutdownFirebase();
    terminateUserRecordListener();
    terminateAuthListeners();
    if (this->listener)
    {
        delete this->listener;
        this->listener = nullptr;
    }
}


static flutter::EncodableValue CreateResponseObject(
    const firebase::Variant &fbf_return_val) {
  if (fbf_return_val.is_null()) {
    return flutter::EncodableValue();
  }
  if (fbf_return_val.is_map()) {
    flutter::EncodableMap response;
    const auto mymap = fbf_return_val.map();

    for (auto it = mymap.begin(); it != mymap.end(); ++it) {
      if (!it->first.is_string()) {
        std::cerr << "function return map must use string keys\n";
        throw std::runtime_error("function return map must use string keys\n");
      }
      std::string key = it->first.string_value();
      auto val = it->second;

      if (val.is_string())
        response.insert({flutter::EncodableValue(key), flutter::EncodableValue(val.string_value())});
      else if (val.is_bool())
        response.insert({flutter::EncodableValue(key), flutter::EncodableValue(val.bool_value())});
      else if (val.is_double())
        response.insert({flutter::EncodableValue(key), flutter::EncodableValue(val.double_value())});
      else if (val.is_int64())
          response.insert({ flutter::EncodableValue(key), flutter::EncodableValue(val.int64_value()) });
      else if (val.is_map())
          response.insert({ flutter::EncodableValue(key), CreateResponseObject(val) });
      else if (val.is_null())
        response.insert({flutter::EncodableValue(key), flutter::EncodableValue(nullptr)});
      else {
        std::cerr << "function return type must be scalar type\n";
        throw std::runtime_error("function return type must be scalar type\n");
      }
    }
    return flutter::EncodableValue(response);

  } else if (fbf_return_val.is_container_type()) {
    std::cerr << "function return type must be scalar type\n";
    throw std::runtime_error("function return type must be scalar type\n");
  }
  flutter::EncodableValue response;
  // for (const firebase::Variant &filename : filenames) {
  if (fbf_return_val.is_string())
    response = flutter::EncodableValue(fbf_return_val.string_value());
  else if (fbf_return_val.is_bool())
    response = flutter::EncodableValue(fbf_return_val.bool_value());
  else if (fbf_return_val.is_double())
    response = flutter::EncodableValue(fbf_return_val.double_value());
  else if (fbf_return_val.is_int64())
    response = flutter::EncodableValue(fbf_return_val.int64_value());
  else if (fbf_return_val.is_null())
    response = flutter::EncodableValue(nullptr);
  return response;
}


void FbfunctionsPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    
  if (method_call.method_name().compare("fbfunctions") == 0) {
    if (!method_call.arguments() || method_call.arguments()->IsNull()) {
      result->Error("Bad Arguments", "Null file chooser method args received");
      return;
    }
    firebase::Variant variant_result;
    
    const flutter::EncodableMap& args = method_call.arguments()->MapValue();

    auto it = args.find(flutter::EncodableValue("methodName"));
    std::string methodName;
    if (it != args.end()) {
      methodName = it->second.StringValue();
    }
    std::cout << methodName << std::endl;
    if (methodName == "authenticate") {
      std::cout << "AUTHENTICATE" << std::endl;
      if (myuid == "" || mysecret == "")
      {
        //ugly, but using result->Error apparently creates uncatchable exceptions.
        flutter::EncodableValue response_object(CreateResponseObject(firebase::Variant("files_missing")));
        result->Success(&response_object);
        return;
      }

      bool signInResult = authenticate(myuid, mysecret);
      variant_result = firebase::Variant(signInResult ? "successful" : "unsuccessful");
    }
    else if (methodName == "signout") {
        if(auth != nullptr)
            auth->SignOut();
        terminateUserRecordListener();
        deleteAuthFiles();
        listener = listenForUIDUpdate();
        
    } 
    else if (methodName == "newRecommendation") 
    {
        newRecommendation(args.begin()->second.StringValue());
    }
    else {
      firebase::auth::User* current_user = auth->current_user();
      if (current_user != nullptr) {
        firebase::Future<std::string> idToken = current_user->GetToken(true);
        WaitForCompletion(idToken, "idToken");
        // Send token to your backend via HTTPS
        // ...
      }
      else
      {
        printf("User is NULL\n");
      }
      std::map<std::string, firebase::Variant> data;
      
      for (it = args.begin(); it != args.end(); ++it)
        data[it->first.StringValue()] = firebase::Variant(it->second.StringValue());
      variant_result =
          callFBFunctionSync(methodName.c_str(), &data);
    }

    flutter::EncodableValue response_object(CreateResponseObject(variant_result));
    result->Success(&response_object);

  } else {
    result->NotImplemented();
  }

}

}  // namespace

void FbfunctionsPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  // The plugin registrar wrappers owns the plugins, registered callbacks, etc.,
  // so must remain valid for the life of the application.
  static auto *plugin_registrars =
      new std::map<FlutterDesktopPluginRegistrarRef,
                   std::unique_ptr<flutter::PluginRegistrarWindows>>;
  auto insert_result = plugin_registrars->emplace(
      registrar, std::make_unique<flutter::PluginRegistrarWindows>(registrar));

  FbfunctionsPlugin::RegisterWithRegistrar(insert_result.first->second.get());
}
