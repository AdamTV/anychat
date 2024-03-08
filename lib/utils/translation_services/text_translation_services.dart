import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart';

class TextTranslationService {
  static Map<String, dynamic> queryParameters = {};
  static const String apiKey = "AIzaSyATyV6do7Ov4MkT55jyBKW_0gaZL8qE3Vw";
  static const String authority = "translation.googleapis.com";
  static const String unencodedPath = "/language/translate/v2";

  static Future<String> getGoogleTranslation(
    String? language,
    String? text,
  ) async {
    queryParameters.putIfAbsent("key", () => apiKey);
    final String? isoCode = language;
    queryParameters.update(
      "target",
      (value) => isoCode,
      ifAbsent: () => isoCode,
    );
    queryParameters.update("q", (value) => text, ifAbsent: () => text);
    final uri = Uri.https(authority, unencodedPath, queryParameters);
    Logs().d(uri.toString());
    final http.Response x = await http.post(uri);
    final String body = x.body;
    Logs().d(body);
    final RegExp translatedTextRegex =
        RegExp("translatedText(?:.*?\"){2}([^\"]+)");
    final Iterable<Match> matches = translatedTextRegex.allMatches(body);
    if (matches.length == 1 && matches.first.groupCount == 1) {
      return matches.first.group(1)!.replaceAll("&#39;", "'");
    } else {
      throw Exception("Could not getGoogleTranslation -> uri: $uri");
    }
    // Logging.d(body);
  }
}
