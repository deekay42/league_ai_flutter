#import "FbfunctionsPlugin.h"
#if __has_include(<fbfunctions/fbfunctions-Swift.h>)
#import <fbfunctions/fbfunctions-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "fbfunctions-Swift.h"
#endif

@implementation FbfunctionsPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFbfunctionsPlugin registerWithRegistrar:registrar];
}
@end
