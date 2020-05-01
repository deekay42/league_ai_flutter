import 'dart:async';

import 'package:flutter/services.dart';

class Fbfunctions {
  static const MethodChannel _channel =
      const MethodChannel('fbfunctions');

  static Future<dynamic> fb_call({String methodName, Map args}) {
    Completer<dynamic> callResult = Completer<dynamic>();
    try {
      if(args == null)
        args = Map<String, dynamic>();
      args["methodName"] = methodName;
      _channel
          .invokeMethod("fbfunctions", args)
          .then((response) {
        callResult.complete(response != null ? (response is List ? response[0] : response) : null);
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
}
