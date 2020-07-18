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

// Plugin channel constants. See common/channel_constants.h for details.
const String _kChannelName = 'flutter/btnonce';
const String _kShowOpenPanelMethod = 'BTNonce.Show.Open';


/// A singleton object that controls file-choosing interactions with macOS.
class BTNonceChannelController {
  BTNonceChannelController._();

  /// The platform channel used to manage native file chooser affordances.
  final _channel = new MethodChannel(_kChannelName, new JSONMethodCodec());

  /// A reference to the singleton instance of the class.
  static final BTNonceChannelController instance =
      new BTNonceChannelController._();


  Future<String> finishPayment({String clientToken}) {
    Completer<String> callResult = Completer<String>();
    try {
      
      var args = Map<String, dynamic>();
      args["clientToken"] = clientToken;
      _channel
          .invokeMethod(_kShowOpenPanelMethod, args)
          .then((response) {
        
        callResult.complete(response != null ? response[0] : null);
      });
    } on PlatformException catch (e) {
      print('BTNonce plugin failure: ${e.message}');
      callResult.completeError(e);
    } on Exception catch (e, s) {
      print('Exception during BTNonce operation: $e\n$s');
      callResult.completeError(e);
    }
    return callResult.future;
  }
}
