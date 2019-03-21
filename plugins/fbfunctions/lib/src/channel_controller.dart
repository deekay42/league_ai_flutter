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
import 'package:flutter/services.dart';
import 'dart:async';

import 'callbacks.dart';

// Plugin channel constants. See common/channel_constants.h for details.
const String _kChannelName = 'flutter/fbfunctions';
const String _kShowOpenPanelMethod = 'FBFunctions.Call';

/// A File chooser type.
enum FBFunctionsType {
  /// An open panel, for choosing one or more files to open.
  open,

  /// A save panel, for choosing where to save a file.
  save,
}

/// A singleton object that controls file-choosing interactions with macOS.
class FBFunctionsChannelController {
  FBFunctionsChannelController._();

  /// The platform channel used to manage native file chooser affordances.
  final _channel = new MethodChannel(_kChannelName, new JSONMethodCodec());

  /// A reference to the singleton instance of the class.
  static final FBFunctionsChannelController instance =
      new FBFunctionsChannelController._();

Future<dynamic> call({String methodName, Map args}) {
    Completer<dynamic> callResult = Completer<dynamic>();
    try {
      if(args == null)
        args = Map<String, dynamic>();
      args["methodName"] = methodName;
      _channel
          .invokeMethod(_kShowOpenPanelMethod, args)
          .then((response) {
        
        callResult.complete(response != null ? response[0] : null);
      });
    } on PlatformException catch (e) {
      print('FBFunctions plugin failure: ${e.message}');
      callResult.completeError(e);
    } on Exception catch (e, s) {
      print('Exception during FBFunctions operation: $e\n$s');
      callResult.completeError(e);
    }
    return callResult.future;
  }

  /// Shows a file chooser of [type] configured with [options], calling
  /// [callback] when it completes.
  // void show(FBFunctionsType type, FBFunctionsConfigurationOptions options,
  //     FBFunctionsCallback callback) {
  //   try {
  //     final methodName = type == FBFunctionsType.open
  //         ? _kShowOpenPanelMethod
  //         : _kShowSavePanelMethod;
  //     _channel
  //         .invokeMethod(methodName, options.asInvokeMethodArguments())
  //         .then((response) {
  //       final paths = response?.cast<String>();
  //       final result =
  //           paths == null ? FBFunctionsResult.cancel : FBFunctionsResult.ok;
  //       callback(result, paths);
  //     });
  //   } on PlatformException catch (e) {
  //     print('FBFunctions plugin failure: ${e.message}');
  //   } on Exception catch (e, s) {
  //     print('Exception during FBFunctions operation: $e\n$s');
  //   }
  // }
}
