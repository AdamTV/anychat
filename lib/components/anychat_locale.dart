import 'package:devicelocale/devicelocale.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AnyChatLocale {
  static List languages;
  static String currentLocale;
  static String humanReadable;
  static Map<String, String> isoMap = Map<String, String>();

  static Future<void> init(BuildContext context) async {
    AnyChatLocale.isoMap = {
      AppLocalizations.of(context).af_endonym : "af",
      AppLocalizations.of(context).sq_endonym : "sq",
      AppLocalizations.of(context).am_endonym : "am",
      AppLocalizations.of(context).ar_endonym : "ar",
      AppLocalizations.of(context).hy_endonym : "hy",
      AppLocalizations.of(context).az_endonym : "az",
      AppLocalizations.of(context).eu_endonym : "eu",
      AppLocalizations.of(context).be_endonym : "be",
      AppLocalizations.of(context).bn_endonym : "bn",
      AppLocalizations.of(context).bs_endonym : "bs",
      AppLocalizations.of(context).bg_endonym : "bg",
      AppLocalizations.of(context).ca_endonym : "ca",
      AppLocalizations.of(context).ceb_endonym : "ceb",
      AppLocalizations.of(context).zh_CN_endonym : "zh-CN",
      AppLocalizations.of(context).zh_TW_endonym : "zh-TW",
      AppLocalizations.of(context).co_endonym : "co",
      AppLocalizations.of(context).hr_endonym : "hr",
      AppLocalizations.of(context).cs_endonym : "cs",
      AppLocalizations.of(context).da_endonym : "da",
      AppLocalizations.of(context).nl_endonym : "nl",
      AppLocalizations.of(context).en_endonym : "en",
      AppLocalizations.of(context).eo_endonym : "eo",
      AppLocalizations.of(context).et_endonym : "et",
      AppLocalizations.of(context).fi_endonym : "fi",
      AppLocalizations.of(context).fr_endonym : "fr",
      AppLocalizations.of(context).fy_endonym : "fy",
      AppLocalizations.of(context).gl_endonym : "gl",
      AppLocalizations.of(context).ka_endonym : "ka",
      AppLocalizations.of(context).de_endonym : "de",
      AppLocalizations.of(context).el_endonym : "el",
      AppLocalizations.of(context).gu_endonym : "gu",
      AppLocalizations.of(context).ht_endonym : "ht",
      AppLocalizations.of(context).ha_endonym : "ha",
      AppLocalizations.of(context).haw_endonym : "haw",
      AppLocalizations.of(context).iw_endonym : "iw",
      AppLocalizations.of(context).hi_endonym : "hi",
      AppLocalizations.of(context).hmn_endonym : "hmn",
      AppLocalizations.of(context).hu_endonym : "hu",
      AppLocalizations.of(context).is_endonym : "is",
      AppLocalizations.of(context).ig_endonym : "ig",
      AppLocalizations.of(context).id_endonym : "id",
      AppLocalizations.of(context).ga_endonym : "ga",
      AppLocalizations.of(context).it_endonym : "it",
      AppLocalizations.of(context).ja_endonym : "ja",
      AppLocalizations.of(context).jv_endonym : "jv",
      AppLocalizations.of(context).kn_endonym : "kn",
      AppLocalizations.of(context).kk_endonym : "kk",
      AppLocalizations.of(context).km_endonym : "km",
      AppLocalizations.of(context).rw_endonym : "rw",
      AppLocalizations.of(context).ko_endonym : "ko",
      AppLocalizations.of(context).ku_endonym : "ku",
      AppLocalizations.of(context).ky_endonym : "ky",
      AppLocalizations.of(context).lo_endonym : "lo",
      AppLocalizations.of(context).la_endonym : "la",
      AppLocalizations.of(context).lv_endonym : "lv",
      AppLocalizations.of(context).lt_endonym : "lt",
      AppLocalizations.of(context).lb_endonym : "lb",
      AppLocalizations.of(context).mk_endonym : "mk",
      AppLocalizations.of(context).mg_endonym : "mg",
      AppLocalizations.of(context).ms_endonym : "ms",
      AppLocalizations.of(context).ml_endonym : "ml",
      AppLocalizations.of(context).mt_endonym : "mt",
      AppLocalizations.of(context).mi_endonym : "mi",
      AppLocalizations.of(context).mr_endonym : "mr",
      AppLocalizations.of(context).mn_endonym : "mn",
      AppLocalizations.of(context).my_endonym : "my",
      AppLocalizations.of(context).ne_endonym : "ne",
      AppLocalizations.of(context).no_endonym : "no",
      AppLocalizations.of(context).ny_endonym : "ny",
      AppLocalizations.of(context).or_endonym : "or",
      AppLocalizations.of(context).ps_endonym : "ps",
      AppLocalizations.of(context).fa_endonym : "fa",
      AppLocalizations.of(context).pl_endonym : "pl",
      AppLocalizations.of(context).pt_endonym : "pt",
      AppLocalizations.of(context).pa_endonym : "pa",
      AppLocalizations.of(context).ro_endonym : "ro",
      AppLocalizations.of(context).ru_endonym : "ru",
      AppLocalizations.of(context).sm_endonym : "sm",
      AppLocalizations.of(context).gd_endonym : "gd",
      AppLocalizations.of(context).sr_endonym : "sr",
      AppLocalizations.of(context).st_endonym : "st",
      AppLocalizations.of(context).sn_endonym : "sn",
      AppLocalizations.of(context).sd_endonym : "sd",
      AppLocalizations.of(context).si_endonym : "si",
      AppLocalizations.of(context).sk_endonym : "sk",
      AppLocalizations.of(context).sl_endonym : "sl",
      AppLocalizations.of(context).so_endonym : "so",
      AppLocalizations.of(context).es_endonym : "es",
      AppLocalizations.of(context).su_endonym : "su",
      AppLocalizations.of(context).sw_endonym : "sw",
      AppLocalizations.of(context).sv_endonym : "sv",
      AppLocalizations.of(context).tl_endonym : "tl",
      AppLocalizations.of(context).tg_endonym : "tg",
      AppLocalizations.of(context).ta_endonym : "ta",
      AppLocalizations.of(context).tt_endonym : "tt",
      AppLocalizations.of(context).te_endonym : "te",
      AppLocalizations.of(context).th_endonym : "th",
      AppLocalizations.of(context).tr_endonym : "tr",
      AppLocalizations.of(context).tk_endonym : "tk",
      AppLocalizations.of(context).uk_endonym : "uk",
      AppLocalizations.of(context).ur_endonym : "ur",
      AppLocalizations.of(context).ug_endonym : "ug",
      AppLocalizations.of(context).uz_endonym : "uz",
      AppLocalizations.of(context).vi_endonym : "vi",
      AppLocalizations.of(context).cy_endonym : "cy",
      AppLocalizations.of(context).xh_endonym : "xh",
      AppLocalizations.of(context).yi_endonym : "yi",
      AppLocalizations.of(context).yo_endonym : "yo",
      AppLocalizations.of(context).zu_endonym : "zu"
    };
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      languages = await Devicelocale.preferredLanguages;
      //print(languages);
    } on PlatformException {
      print("Error obtaining preferred languages");
    }
    try {
      // var locale = Devicelocale();
      currentLocale = await Devicelocale.currentLocale;
      print(currentLocale);
    } on PlatformException {
      print("Error obtaining current locale");
    }
  }
}
