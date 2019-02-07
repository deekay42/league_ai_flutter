#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"
#import "BraintreeCore.h"
#import "BraintreeDropIn.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    if ([url.scheme localizedCaseInsensitiveCompare:@"com.leagueiq.app.payments"] == NSOrderedSame) {
        return [BTAppSwitch handleOpenURL:url options:options];
    }
    return NO;
}

// If you support iOS 7 or 8, add the following method.
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    if ([url.scheme localizedCaseInsensitiveCompare:@"com.leagueiq.app.payments"] == NSOrderedSame) {
        return [BTAppSwitch handleOpenURL:url sourceApplication:sourceApplication];
    }
    return NO;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  FlutterViewController* controller = (FlutterViewController*)self.window.rootViewController;

  FlutterMethodChannel* paymentChannel = [FlutterMethodChannel
                                          methodChannelWithName:@"getPaymentNonce"
                                          binaryMessenger:controller];
  [BTAppSwitch setReturnURLScheme:@"com.leagueiq.app.payments"];

  __weak typeof(self) weakSelf = self;

  [paymentChannel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
    if ([@"getPaymentNonce" isEqualToString:call.method]) {
        NSString *clientToken = call.arguments[@"clientToken"];
        [weakSelf getPaymentNonce:clientToken callback:result];
      } else {
        result(FlutterMethodNotImplemented);
      }
  }];

  [GeneratedPluginRegistrant registerWithRegistry:self];
  // Override point for customization after application launch.
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)getPaymentNonce: (NSString*) clientToken callback:(FlutterResult) callback {
  __weak typeof(self) weakSelf = self;
  [weakSelf showDropIn:clientToken callback:callback];
}

- (void)showDropIn:(NSString *)clientTokenOrTokenizationKey callback:(FlutterResult) callback{

    [BTUIKAppearance sharedInstance].useBlurs = YES;

    BTDropInRequest *request = [[BTDropInRequest alloc] init];
    BTDropInController *dropIn = [[BTDropInController alloc] initWithAuthorization:clientTokenOrTokenizationKey request:request handler:^(BTDropInController * _Nonnull controller, BTDropInResult * _Nullable result, NSError * _Nullable error) {

        if (error != nil) {
            NSLog(@"ERROR");
        } else if (result.cancelled) {
            NSLog(@"CANCELLED");
        } else {

            NSString* nonce = result.paymentMethod.nonce;
            NSString* desc = result.paymentDescription;
            NSString* type = result.paymentMethod.type;


            if ([@"" isEqualToString:nonce]) {
                              callback([FlutterError errorWithCode:@"UNAVAILABLE"
                                                         message:@"Unable to obtain nonce"
                                                         details:nil]);
                            }


            callback(@[nonce, [NSString stringWithFormat:@"%@ %@", type, desc]]);
            // Use the BTDropInResult properties to update your UI
            // result.paymentOptionType
            // result.paymentMethod
            // result.paymentIcon
            // result.paymentDescription
        }
        [controller dismissViewControllerAnimated:YES completion:nil];
    }];
    [self.window.rootViewController presentViewController:dropIn animated:YES completion:nil];
}

@end
