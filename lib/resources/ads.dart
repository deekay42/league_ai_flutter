import 'package:firebase_admob/firebase_admob.dart';
import '../resources/Strings.dart';
import 'dart:async';
import 'dart:io';

class Ads {
  final MobileAdTargetingInfo targetingInfo;

  Ads()
      : targetingInfo = MobileAdTargetingInfo(
          keywords: <String>['League of Legends', 'League', 'Gaming', 'Online Gaming', 'MMORPG', 'Game', 'Gamer'],
          childDirected: true,
          testDevices: <
              String>[], // Android emulators are considered test devices
        ) {
    FirebaseAdMob.instance.initialize(appId: Platform.isIOS ? Strings.IOS_adMobAppId : Strings.ANDROID_adMobAppId);
  }

  Future<BannerAd> getBannerAd() async {
    BannerAd ad = BannerAd(
      // Replace the testAdUnitId with an ad unit id from the AdMob dash.
      // https://developers.google.com/admob/android/test-ads
      // https://developers.google.com/admob/ios/test-ads
      adUnitId: Platform.isIOS ? Strings.IOS_adMobAdUnitId : Strings.ANDROID_adMobAdUnitId,
      size: AdSize.smartBanner,
      targetingInfo: targetingInfo,
      listener: (MobileAdEvent event) {
        print("BannerAd event is $event");
      },
    );
    await ad.load();
    return ad;
  }

  Future<InterstitialAd> getInterstitialAd() async {
    InterstitialAd ad = InterstitialAd(
      // Replace the testAdUnitId with an ad unit id from the AdMob dash.
      // https://developers.google.com/admob/android/test-ads
      // https://developers.google.com/admob/ios/test-ads
      adUnitId: InterstitialAd.testAdUnitId,
      targetingInfo: targetingInfo,
      listener: (MobileAdEvent event) {
        print("InterstitialAd event is $event");
      },
    );
    await ad.load();
    return ad;
  }
}
