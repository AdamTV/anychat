import 'package:devicelocale/devicelocale.dart';
import 'package:flutter/services.dart';

class locale {
  static List languages;
  static String currentLocale;
  static String humanReadable;

  static Future<void> init() async {
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      languages = await Devicelocale.preferredLanguages;
      print(languages);
    } on PlatformException {
      print("Error obtaining preferred languages");
    }
    try {
      var locale = Devicelocale();
      currentLocale = await Devicelocale.currentLocale;
      LocaleToHumanReadable();
      print(currentLocale);
    } on PlatformException {
      print("Error obtaining current locale");
    }
  }

  static void LocaleToHumanReadable() {
    switch (currentLocale) {
      case "en_US":
        {
          humanReadable = "English";
        }
        break;
      default:
        {
          humanReadable = currentLocale;
        }
        break;
    }
  }

}