import 'package:admob_flutter/admob_flutter.dart';
import 'package:anychat/components/utilities.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

class Ads {
  static AdmobInterstitial interstitial;

  static init() {
    // Admob.initialize();
    Admob.initialize(testDeviceIds: [
      'ee20dbf2-4928-4348-876e-c731bd0d5daf', // Pexel 3a
      '6cc2ce0e-3a4f-41a7-9295-550e91e1a85e', // Nexus 5
      'f9fb4813-3745-489e-b55c-4c3adb59b3f5', // Nexus 7
      'c3f51604-1258-4021-948a-e2818e7a91b4', // Nexus 10
      'eea7bfde-2c6f-489b-930e-c98b498f424f', // OP 5T
      '0ED527776873F3E56A11C1BDB9A1A3D2', // SM T290
      '9FE872DB63EEA34B32A3296F08C2DE1E', // Mac Android
    ]);

    interstitial = AdmobInterstitial(
      adUnitId: getInterstitialAdUnitId(),
      listener: (AdmobAdEvent event, Map<String, dynamic> args) {
        handleEvent(event, args, 'Interstitial');
      },
    );

    interstitial.load();
  }

  static AdmobBannerController controller;
  static AdmobBanner getBanner() {
    return AdmobBanner(
        adUnitId: getBannerAdUnitId(),
        adSize:
            AdmobBannerSize.SMART_BANNER(Utilities.globalKey.currentContext),
        listener: (AdmobAdEvent event, Map<String, dynamic> args) {
          handleEvent(event, args, 'Banner');
          if (event == AdmobAdEvent.opened) {
            controller.dispose();
          }
        },
        onBannerCreated: (AdmobBannerController controller) {
          // Dispose is called automatically for you when Flutter removes the banner from the widget tree.
          // Normally you don't need to worry about disposing this yourself, it's handled.
          // If you need direct access to dispose, this is your guy!
          // controller.dispose();
          Ads.controller = controller;
        });
  }

  static void handleEvent(
      AdmobAdEvent event, Map<String, dynamic> args, String adType) {
    switch (event) {
      case AdmobAdEvent.loaded:
        print('New Admob $adType Ad loaded!');
        break;
      case AdmobAdEvent.opened:
        print('Admob $adType Ad opened!');
        break;
      case AdmobAdEvent.closed:
        print('Admob $adType Ad closed!');
        if (adType == "Interstitial") {
          interstitial.load();
        }
        break;
      case AdmobAdEvent.failedToLoad:
        print('Admob $adType failed to load. :(');
        break;
      // case AdmobAdEvent.rewarded:
      //   showDialog(
      //     context: scaffoldState.currentContext,
      //     builder: (BuildContext context) {
      //       return WillPopScope(
      //         child: AlertDialog(
      //           content: Column(
      //             mainAxisSize: MainAxisSize.min,
      //             children: <Widget>[
      //               Text('Reward callback fired. Thanks Andrew!'),
      //               Text('Type: ${args['type']}'),
      //               Text('Amount: ${args['amount']}'),
      //             ],
      //           ),
      //         ),
      //         onWillPop: () async {
      //           scaffoldState.currentState.hideCurrentSnackBar();
      //           return true;
      //         },
      //       );
      //     },
      //   );
      //   break;
      default:
    }
  }

  static String getBannerAdUnitId() {
    // return AdmobBanner.testAdUnitId;
    return defaultTargetPlatform == TargetPlatform.iOS
        ? "ca-app-pub-4494853791237895/9609705015"
        : "ca-app-pub-4494853791237895/9276436590";
    // : "ca-app-pub-4494853791237895/1975328398";
  }

  static String getInterstitialAdUnitId() {
    // return AdmobInterstitial.testAdUnitId;
    return defaultTargetPlatform == TargetPlatform.iOS
        ? "ca-app-pub-4494853791237895/8261798477"
        : "ca-app-pub-4494853791237895/4091843930";
    // : "ca-app-pub-4494853791237895/1975328398";
  }
}
