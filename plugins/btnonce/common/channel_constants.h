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
#ifndef PLUGINS_BT_NONCE_COMMON_CHANNEL_CONSTANTS_H_
#define PLUGINS_BT_NONCE_COMMON_CHANNEL_CONSTANTS_H_

namespace plugins_btnonce {

// This file contains constants used in the platform channel, which are shared
// across all native platform implementations.

// The name of the plugin's platform channel.
extern const char kChannelName[];

// The method name to instruct the native plugin to show an open panel.
extern const char kShowOpenPanelMethod[];

}  // namespace plugins_file_chooser

#endif  // PLUGINS_FILE_CHOOSER_COMMON_CHANNEL_CONSTANTS_H_
