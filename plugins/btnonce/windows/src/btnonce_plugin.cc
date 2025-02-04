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
#include "btnonce/btnonce_plugin.h"
#define WEBVIEW_IMPLEMENTATION
#include "btnonce/webview.h"

#include "json/json.h"
#include <iostream>
#include <memory>
#include <vector>

#include <flutter/json_method_codec.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar.h>

// File chooser callback results.
static constexpr int kCancelResultValue = 0;
static constexpr int kOkResultValue = 1;

const char kChannelName[] = "flutter/btnonce";


const char* global_client_token = "lol";

namespace plugins_btnonce {

class BTNoncePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(
      flutter::PluginRegistrar *registrar);

  virtual ~BTNoncePlugin();

 private:
  // Creates a plugin that communicates on the given channel.
  BTNoncePlugin(
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


// // Applies filters to the file chooser.
// //
// // Takes the JSON method args and attempts to apply filters to the file chooser
// // (in the event that they exist).
// static void ProcessFilters(const Json::Value &method_args,
//                            GtkFileChooser *chooser) {
//   Json::Value allowed_file_types = method_args[kAllowedFileTypesKey];
//   if (!allowed_file_types.empty() && allowed_file_types.isArray()) {
//     GtkFileFilter *filter = gtk_file_filter_new();
//     const std::string comma_delimiter = ", ";
//     const std::string file_wildcard = "*.";
//     std::string filter_name = "";
//     for (const Json::Value &element : allowed_file_types) {
//       std::string pattern = file_wildcard + element.asString();
//       filter_name.append(pattern + comma_delimiter);
//       gtk_file_filter_add_pattern(filter, pattern.c_str());
//     }
//     // Deletes trailing comma and space.
//     filter_name.erase(filter_name.end() - comma_delimiter.size(),
//                       filter_name.end());
//     gtk_file_filter_set_name(filter, filter_name.c_str());
//     gtk_file_chooser_add_filter(GTK_FILE_CHOOSER(chooser), filter);
//   }
// }

// // Applies attributes from method args to the file chooser.
// //
// // Take the JSON method args and attempts to apply the possible attributes that
// // would modify the file chooser: whether multiple files can be selected,
// // whether a directory is a valid target, etc.
// static void ProcessAttributes(const Json::Value &method_args,
//                               GtkFileChooser *chooser) {
//   if (!method_args[kAllowsMultipleSelectionKey].isNull()) {
//     gtk_file_chooser_set_select_multiple(
//         chooser, method_args[kAllowsMultipleSelectionKey].asBool());
//   }
//   Json::Value choose_dirs = method_args[kCanChooseDirectoriesKey];
//   if (!choose_dirs.isNull() && choose_dirs.asBool()) {
//     gtk_file_chooser_set_action(chooser, GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER);
//   }
//   Json::Value start_dir = method_args[kInitialDirectoryKey];
//   if (!start_dir.isNull()) {
//     std::string start_dir_str(start_dir.asString());
//     gtk_file_chooser_set_current_folder(chooser, start_dir_str.c_str());
//   }
//   Json::Value initial_file_name = method_args[kInitialFileNameKey];
//   if (!initial_file_name.isNull()) {
//     std::string initial_file_name_str(initial_file_name.asString());
//     gtk_file_chooser_set_current_name(chooser, initial_file_name_str.c_str());
//   }
// }

// // Creates a file chooser based on the method type.
// //
// // If the method type is the open method (defined under kShowOpenFileMethod),
// // then this returns a file opener dialog. If it is a kShowSaveFileMethod
// // string, then this returns a file saver dialog.
// //
// // If the method is not recognized as one of those above, will return a nullptr.
// static GtkWidget *CreateFileChooserFromMethod(const std::string &method,
//                                               const std::string &ok_button) {
//   GtkWidget *chooser = nullptr;
//   if (method == kShowOpenPanelMethod) {
//     GtkFileChooserAction action = GTK_FILE_CHOOSER_ACTION_OPEN;
//     chooser = gtk_file_chooser_dialog_new(
//         "Open File", NULL, action,
//         ok_button.empty() ? "_Open" : ok_button.c_str(), GTK_RESPONSE_ACCEPT,
//         "_Cancel", GTK_RESPONSE_CANCEL, NULL);
//   } else if (method == kShowSavePanelMethod) {
//     GtkFileChooserAction action = GTK_FILE_CHOOSER_ACTION_SAVE;
//     chooser = gtk_file_chooser_dialog_new(
//         "Save File", NULL, action,
//         ok_button.empty() ? "_Save" : ok_button.c_str(), GTK_RESPONSE_ACCEPT,
//         "_Cancel", GTK_RESPONSE_CANCEL, NULL);
//   }
//   return chooser;
// }

// // Creates a native file chooser based on the method specified.
// //
// // The JSON args determine the modifications to the file chooser, like filters,
// // being able to choose multiple files, etc.
// static GtkWidget *CreateFileChooser(const std::string &method,
//                                     const Json::Value &args) {
//   Json::Value ok_button_value = args[kConfirmButtonTextKey];
//   std::string ok_button_str;
//   if (!ok_button_value.isNull()) {
//     ok_button_str = ok_button_value.asString();
//   }
//   GtkWidget *chooser = CreateFileChooserFromMethod(method, ok_button_str);
//   if (chooser == nullptr) {
//     std::cerr << "Could not determine method for file chooser from: " << method
//               << std::endl;
//     return chooser;
//   }
//   ProcessFilters(args, GTK_FILE_CHOOSER(chooser));
//   ProcessAttributes(args, GTK_FILE_CHOOSER(chooser));
//   return chooser;
// }

// Creates a valid response JSON object given the list of filenames.
//
// An empty array is treated as a cancelled operation.
static Json::Value CreateResponseObject(
    const std::vector<std::string> &filenames) {
  if (filenames.empty()) {
    return Json::Value();
  }
  Json::Value response(Json::arrayValue);
  for (const std::string &filename : filenames) {
    response.append(filename);
  }
  return response;
}

// static
void BTNoncePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrar *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<Json::Value>>(
          registrar->messenger(), kChannelName,
          &flutter::JsonMethodCodec::GetInstance());
  auto *channel_pointer = channel.get();

  // Uses new instead of make_unique due to private constructor.
  std::unique_ptr<BTNoncePlugin> plugin(
      new BTNoncePlugin(std::move(channel)));

  channel_pointer->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });
  registrar->EnableInputBlockingForChannel(kChannelName);

  registrar->AddPlugin(std::move(plugin));
}

BTNoncePlugin::BTNoncePlugin(
    std::unique_ptr<flutter::MethodChannel<Json::Value>>
        channel)
    : channel_(std::move(channel)) {}

BTNoncePlugin::~BTNoncePlugin() {}

void hexchar(unsigned char c, unsigned char &hex1, unsigned char &hex2)
{
    hex1 = c / 16;
    hex2 = c % 16;
    hex1 += hex1 <= 9 ? '0' : 'a' - 10;
    hex2 += hex2 <= 9 ? '0' : 'a' - 10;
}

std::string urlencode(std::string s)
{
    const char *str = s.c_str();
    std::vector<char> v(s.size());
    v.clear();
    for (size_t i = 0, l = s.size(); i < l; i++)
    {
        char c = str[i];
        if ((c >= '0' && c <= '9') ||
            (c >= 'a' && c <= 'z') ||
            (c >= 'A' && c <= 'Z') ||
            c == '-' || c == '_' || c == '.' || c == '!' || c == '~' ||
            c == '*' || c == '\'' || c == '(' || c == ')')
        {
            v.push_back(c);
        }
        else if (c == ' ')
        {
            v.push_back('+');
        }
        else
        {
            v.push_back('%');
            unsigned char d1, d2;
            hexchar(c, d1, d2);
            v.push_back(d1);
            v.push_back(d2);
        }
    }

    return std::string(v.cbegin(), v.cend());
}

void BTNoncePlugin::HandleMethodCall(
    const flutter::MethodCall<Json::Value> &method_call,
    std::unique_ptr<flutter::MethodResult<Json::Value>>
        result) {
  if (!method_call.arguments() || method_call.arguments()->isNull()) {
    result->Error("Bad Arguments", "Null file chooser method args received");
    return;
  }
  const Json::Value &args = *method_call.arguments();
  std::string client_token = args["clientToken"].asString();
  client_token = "client_token=" + client_token;
  global_client_token = client_token.c_str();

  
  std::string url = "https://us-central1-neuralleague.cloudfunctions.net/pay";
  //std::cout << "This is the client_token: " << global_client_token << std::endl;
  //std::cout << "This is the client_token: " << client_token << std::endl;
  
  
webview("Minimal webview example",
	  url.c_str(), 800, 600, 1);
    std::cout << "\nwebview terminated.\n" << std::endl;

    if(cb_result)
      std::cout << " result is: "<< cb_result;
    else
      std::cout << " result is nullptr ";
    std::cout << " AWESOME! " << std::endl;
    
	if (!cb_result) result->Success(&Json::Value());
    else
	{
	  std::vector<std::string> return_result;
	  return_result.push_back(cb_result);
	  Json::Value response_object(CreateResponseObject(return_result));
	  result->Success(&response_object);
	}
  // auto chooser =
  //     CreateFileChooser(method_call.method_name(), *method_call.arguments());
  // if (chooser == nullptr) {
  //   result->NotImplemented();
  //   return;
  // }
  // gint chooser_result = gtk_dialog_run(GTK_DIALOG(chooser));
  // std::vector<std::string> filenames;
  // if (chooser_result == GTK_RESPONSE_ACCEPT) {
  //   GSList *files = gtk_file_chooser_get_filenames(GTK_FILE_CHOOSER(chooser));
  //   // Each filename must be freed, and then GSList afterward:
  //   //
  //   // See:
  //   // https://developer.gnome.org/gtk3/stable/GtkFileChooser.html#gtk-file-chooser-get-filenames
  //   for (GSList *iter = files; iter != nullptr; iter = iter->next) {
  //     std::string filename;
  //     gchar *g_filename = reinterpret_cast<gchar *>(iter->data);
  //     filename.assign(g_filename);
  //     g_free(g_filename);
  //     filenames.push_back(filename);
  //   }
  //   g_slist_free(files);
  // }
  // gtk_widget_destroy(chooser);

  // Json::Value response_object(CreateResponseObject(filenames));
  // result->Success(&response_object);
}

}  // namespace plugins_file_chooser

void BTNonceRegisterWithRegistrar(
	FlutterDesktopPluginRegistrarRef registrar) {
  // The plugin registrar owns the plugin, registered callbacks, etc., so must
  // remain valid for the life of the application.
  static auto *plugin_registrar =
      new flutter::PluginRegistrar(registrar);
  plugins_btnonce::BTNoncePlugin::RegisterWithRegistrar(
      plugin_registrar);
}
