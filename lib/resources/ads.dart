import 'package:firebase_admob/firebase_admob.dart';
import '../resources/Strings.dart';
import 'dart:async';

class Ads {
  final MobileAdTargetingInfo targetingInfo;

  Ads()
      : targetingInfo = MobileAdTargetingInfo(
          keywords: <String>['League of Legends', 'League', 'Gaming', 'Online Gaming', 'MMORPG', 'Game', 'Gamer'],
          childDirected: true,
          testDevices: <
              String>[], // Android emulators are considered test devices
        ) {
    FirebaseAdMob.instance.initialize(appId: Strings.adMobAppId);
  }

  Future<BannerAd> getBannerAd() async {
    BannerAd ad = BannerAd(
      // Replace the testAdUnitId with an ad unit id from the AdMob dash.
      // https://developers.google.com/admob/android/test-ads
      // https://developers.google.com/admob/ios/test-ads
      adUnitId: "ca-app-pub-4748256700093905/4823520849",
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
