import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter/foundation.dart';

class Ads {
  static BannerAd myBanner;
  static InterstitialAd myInterstitial;

  static init() async {
    MobileAdTargetingInfo targetingInfo = MobileAdTargetingInfo(
      keywords: <String>['flutterio', 'beautiful apps'],
      contentUrl: 'https://flutter.io',
      // birthday: DateTime.now(),
      childDirected: false,
      // designedForFamilies: false,
      // gender: MobileAdGender.male, // or MobileAdGender.female, MobileAdGender.unknown
      // testDevices: <String>[], // Android emulators are considered test devices
    );

    myBanner = BannerAd(
      // Replace the testAdUnitId with an ad unit id from the AdMob dash.
      // https://developers.google.com/admob/android/test-ads
      // https://developers.google.com/admob/ios/test-ads
      adUnitId: defaultTargetPlatform == TargetPlatform.iOS
          ? "ca-app-pub-4494853791237895/9609705015"
          : "ca-app-pub-4494853791237895/3946336873",
      // adUnitId: "ca-app-pub-4494853791237895/3946336873",
      // adUnitId: BannerAd.testAdUnitId,
      size: AdSize.smartBanner,
      targetingInfo: targetingInfo,
      listener: (MobileAdEvent event) {
        print("BannerAd event is $event");
        if (event == MobileAdEvent.opened) {
          myBanner.dispose();
          init();
          // Ads();
        }
      },
    );

    myInterstitial = InterstitialAd(
      // Replace the testAdUnitId with an ad unit id from the AdMob dash.
      // https://developers.google.com/admob/android/test-ads
      // https://developers.google.com/admob/ios/test-ads
      adUnitId: defaultTargetPlatform == TargetPlatform.iOS
          ? "ca-app-pub-4494853791237895/8261798477"
          : "ca-app-pub-4494853791237895/1975328398",
      // adUnitId: InterstitialAd.testAdUnitId,
      targetingInfo: targetingInfo,
      listener: (MobileAdEvent event) {
        print("InterstitialAd event is $event");
        if (event == MobileAdEvent.opened) {
          myInterstitial.dispose();
          init();
          // Ads();
        }
      },
    );

    myBanner.load();
    myInterstitial.load();
  }
}
