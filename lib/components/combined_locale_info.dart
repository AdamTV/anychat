import 'package:anychat/components/utilities.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:devicelocale/devicelocale.dart';

List<Locale> getSupportedLocales() {
  List<Locale> supportedLocales = [];
  for (var key in endonymRetrievalMap.keys) {
    supportedLocales.add(Locale(key));
  }
  return supportedLocales;
}

List<DropdownMenuItem<String>>? getLanguageDropdownMenuItems(context) {
  List<DropdownMenuItem<String>>? menuItems = [];
  for (var endonym in endonymRetrievalMap.values) {
    menuItems.add(DropdownMenuItem<String>(
      value: endonym(localizationOf(context)),
      child: Text(endonym(localizationOf(context))),
    ));
  }
  return menuItems;
}

AppLocalizations localizationOf(BuildContext? context) {
  if (context?.mounted ?? false) {
    return AppLocalizations.of(context!)!;
  } else {

    return AppLocalizations.of(Utilities().globalKey.currentContext!)!;
  }
}

String getEndonymByLocaleCode(String code, [AppLocalizations? localizations]) {
  var retrievalFunction = endonymRetrievalMap[code];
  if (retrievalFunction != null) {
    return retrievalFunction(
        localizations ?? localizationOf(Utilities().globalKey.currentContext));
  } else {
    return 'Unknown Locale ($code)';
  }
}

String getLocaleCodeByEndonym(String endonym,
    [AppLocalizations? localizations]) {
  var allEndonyms = getAllEndonyms(localizations ??
      localizationOf(Utilities()
          .globalKey
          .currentContext));

  // Attempt to find the locale code by endonym
  var item = allEndonyms.entries.firstWhere(
        (k) => k.key.trim().toLowerCase() == endonym.trim().toLowerCase(),
    orElse: () => const MapEntry('English', 'en'),
  );
return item.value;
}

Map<String, String> getAllEndonyms(AppLocalizations localizations) {
  Map<String, String> endonymsToCodes = {};

  endonymRetrievalMap.forEach((code, getEndonym) {
    // Use the function to get the endonym for the current code
    String endonym = getEndonym(localizations);
    // Map the endonym back to its locale code
    endonymsToCodes[endonym] = code;
  });

  return endonymsToCodes;
}
Map<String, String Function(AppLocalizations)> endonymRetrievalMap = {
  'af': (localizations) => localizations.endonym_af,
  'sq': (localizations) => localizations.endonym_sq,
  'am': (localizations) => localizations.endonym_am,
  'ar': (localizations) => localizations.endonym_ar,
  'hy': (localizations) => localizations.endonym_hy,
  'az': (localizations) => localizations.endonym_az,
  'eu': (localizations) => localizations.endonym_eu,
  'be': (localizations) => localizations.endonym_be,
  'bn': (localizations) => localizations.endonym_bn,
  'bs': (localizations) => localizations.endonym_bs,
  'bg': (localizations) => localizations.endonym_bg,
  'ca': (localizations) => localizations.endonym_ca,
  // 'ceb': (localizations) => localizations.endonym_ceb,
  'zh-CN': (localizations) => localizations.endonym_zh_CN,
  'zh-TW': (localizations) => localizations.endonym_zh_TW,
  'co': (localizations) => localizations.endonym_co,
  'hr': (localizations) => localizations.endonym_hr,
  'cs': (localizations) => localizations.endonym_cs,
  'da': (localizations) => localizations.endonym_da,
  'nl': (localizations) => localizations.endonym_nl,
  'en': (localizations) => localizations.endonym_en,
  // 'eo': (localizations) => localizations.endonym_eo,
  'et': (localizations) => localizations.endonym_et,
  'fi': (localizations) => localizations.endonym_fi,
  'fr': (localizations) => localizations.endonym_fr,
  // 'fy': (localizations) => localizations.endonym_fy,
  'gl': (localizations) => localizations.endonym_gl,
  'ka': (localizations) => localizations.endonym_ka,
  'de': (localizations) => localizations.endonym_de,
  'el': (localizations) => localizations.endonym_el,
  'gu': (localizations) => localizations.endonym_gu,
  'ht': (localizations) => localizations.endonym_ht,
  // 'ha': (localizations) => localizations.endonym_ha,
  // 'haw': (localizations) => localizations.endonym_haw,
  'iw': (localizations) => localizations.endonym_iw,
  'hi': (localizations) => localizations.endonym_hi,
  'hmn': (localizations) => localizations.endonym_hmn,
  'hu': (localizations) => localizations.endonym_hu,
  'is': (localizations) => localizations.endonym_is,
  // 'ig': (localizations) => localizations.endonym_ig,
  'id': (localizations) => localizations.endonym_id,
  'ga': (localizations) => localizations.endonym_ga,
  'it': (localizations) => localizations.endonym_it,
  'ja': (localizations) => localizations.endonym_ja,
  // 'jv': (localizations) => localizations.endonym_jv,
  'kn': (localizations) => localizations.endonym_kn,
  'kk': (localizations) => localizations.endonym_kk,
  'km': (localizations) => localizations.endonym_km,
  // 'rw': (localizations) => localizations.endonym_rw,
  'ko': (localizations) => localizations.endonym_ko,
  // 'ku': (localizations) => localizations.endonym_ku,
  'ky': (localizations) => localizations.endonym_ky,
  'lo': (localizations) => localizations.endonym_lo,
  // 'la': (localizations) => localizations.endonym_la,
  'lv': (localizations) => localizations.endonym_lv,
  'lt': (localizations) => localizations.endonym_lt,
  // 'lb': (localizations) => localizations.endonym_lb,
  'mk': (localizations) => localizations.endonym_mk,
  // 'mg': (localizations) => localizations.endonym_mg,
  'ms': (localizations) => localizations.endonym_ms,
  'ml': (localizations) => localizations.endonym_ml,
  'mt': (localizations) => localizations.endonym_mt,
  // 'mi': (localizations) => localizations.endonym_mi,
  'mr': (localizations) => localizations.endonym_mr,
  'mn': (localizations) => localizations.endonym_mn,
  'my': (localizations) => localizations.endonym_my,
  'ne': (localizations) => localizations.endonym_ne,
  'no': (localizations) => localizations.endonym_no,
  // 'ny': (localizations) => localizations.endonym_ny,
  'or': (localizations) => localizations.endonym_or,
  // 'ps': (localizations) => localizations.endonym_ps,
  'fa': (localizations) => localizations.endonym_fa,
  'pl': (localizations) => localizations.endonym_pl,
  'pt': (localizations) => localizations.endonym_pt,
  'pa': (localizations) => localizations.endonym_pa,
  'ro': (localizations) => localizations.endonym_ro,
  'ru': (localizations) => localizations.endonym_ru,
  // 'sm': (localizations) => localizations.endonym_sm,
  // 'gd': (localizations) => localizations.endonym_gd,
  'sr': (localizations) => localizations.endonym_sr,
  // 'st': (localizations) => localizations.endonym_st,
  // 'sn': (localizations) => localizations.endonym_sn,
  // 'sd': (localizations) => localizations.endonym_sd,
  'si': (localizations) => localizations.endonym_si,
  'sk': (localizations) => localizations.endonym_sk,
  'sl': (localizations) => localizations.endonym_sl,
  'so': (localizations) => localizations.endonym_so,
  'es': (localizations) => localizations.endonym_es,
  // 'su': (localizations) => localizations.endonym_su,
  'sw': (localizations) => localizations.endonym_sw,
  'sv': (localizations) => localizations.endonym_sv,
  'tl': (localizations) => localizations.endonym_tl,
  // 'tg': (localizations) => localizations.endonym_tg,
  'ta': (localizations) => localizations.endonym_ta,
  // 'tt': (localizations) => localizations.endonym_tt,
  'te': (localizations) => localizations.endonym_te,
  'th': (localizations) => localizations.endonym_th,
  'tr': (localizations) => localizations.endonym_tr,
  'tk': (localizations) => localizations.endonym_tk,
  'uk': (localizations) => localizations.endonym_uk,
  'ur': (localizations) => localizations.endonym_ur,
  // 'ug': (localizations) => localizations.endonym_ug,
  'uz': (localizations) => localizations.endonym_uz,
  'vi': (localizations) => localizations.endonym_vi,
  'cy': (localizations) => localizations.endonym_cy,
  'xh': (localizations) => localizations.endonym_xh,
  // 'yi': (localizations) => localizations.endonym_yi,
  // 'yo': (localizations) => localizations.endonym_yo,
  'zu': (localizations) => localizations.endonym_zu
};
