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
#ifndef PLUGINS_BT_NONCE_WINDOWS_INCLUDE_BT_NONCE_BT_NONCE_PLUGIN_H_
#define PLUGINS_BT_NONCE_WINDOWS_INCLUDE_BT_NONCE_BT_NONCE_PLUGIN_H_

// A plugin to show native save/open file choosers.

#include <flutter_plugin_registrar.h>

#ifdef BTNONCE_PLUGIN_IMPL
#define BTNONCE_PLUGIN_EXPORT __attribute__((visibility("default")))
#else
#define BTNONCE_PLUGIN_EXPORT
#endif

#if defined(__cplusplus)
extern "C" {
#endif

BTNONCE_PLUGIN_EXPORT void BTNonceRegisterWithRegistrar(
	FlutterDesktopPluginRegistrarRef registrar);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // PLUGINS_FILE_CHOOSER_LINUX_INCLUDE_FILE_CHOOSER_FILE_CHOOSER_PLUGIN_H_
