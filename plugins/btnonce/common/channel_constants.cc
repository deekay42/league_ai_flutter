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
#include "plugins/btnonce/common/channel_constants.h"

namespace plugins_btnonce {

const char kChannelName[] = "flutter/btnonce";

const char kShowOpenPanelMethod[] = "BTNonce.Show.Open";
const char kShowSavePanelMethod[] = "BTNonce.Show.Save";

const char kInitialDirectoryKey[] = "initialDirectory";
const char kInitialFileNameKey[] = "initialFileName";
const char kAllowedFileTypesKey[] = "allowedFileTypes";
const char kConfirmButtonTextKey[] = "confirmButtonText";

const char kAllowsMultipleSelectionKey[] = "allowsMultipleSelection";
const char kCanChooseDirectoriesKey[] = "canChooseDirectories";

}  // namespace plugins_file_chooser
