import 'package:cloud_functions/cloud_functions.dart';
import 'package:googleapis_auth/googleapis_auth.dart';

/// Name of the callable that mints short-lived Speech-to-Text access
/// tokens for signed-in users.
const String kSpeechTokenFunction = 'getSpeechAccessToken';

/// OAuth scope carried by every minted Speech-to-Text access token.
const String kSpeechTokenScope =
    'https://www.googleapis.com/auth/cloud-platform';

/// Fetches short-lived Speech-to-Text credentials from the
/// [kSpeechTokenFunction] callable.
///
/// The callable authenticates the caller with Firebase Auth, so no
/// service-account private key ships inside the app bundle anymore.
/// google_speech's ThirdPartyAuthenticator calls this whenever the
/// credentials are missing or about to expire.
///
/// [callable] is injectable for tests; it defaults to the deployed
/// callable in the default Firebase Functions region.
Future<AccessCredentials> fetchSpeechCredentials(
    [HttpsCallable? callable]) async {
  final resolvedCallable = callable ??
      FirebaseFunctions.instance.httpsCallable(kSpeechTokenFunction);
  final result = await resolvedCallable.call<Object?>();
  return speechCredentialsFromCallableResult(result.data);
}

/// Converts the payload returned by the [kSpeechTokenFunction] callable
/// into [AccessCredentials].
///
/// Throws [FormatException] when the payload is malformed so callers see
/// a clear error instead of a failure deep inside the gRPC stack.
AccessCredentials speechCredentialsFromCallableResult(Object? data) {
  if (data is! Map) {
    throw FormatException('Speech token response must be a map, got: $data');
  }
  final accessToken = data['accessToken'];
  final tokenType = data['tokenType'];
  final expirationTime = data['expirationTime'];
  if (accessToken is! String || accessToken.isEmpty) {
    throw FormatException('Speech token response has no accessToken: $data');
  }
  if (tokenType is! String || tokenType.toLowerCase() != 'bearer') {
    throw FormatException(
        'Speech token response does not carry a Bearer token: $data');
  }
  if (expirationTime is! String) {
    throw FormatException('Speech token response has no expirationTime: $data');
  }
  final expiry = DateTime.tryParse(expirationTime);
  if (expiry == null) {
    throw FormatException(
        'Speech token expirationTime is not a valid date: $data');
  }
  return AccessCredentials(
    AccessToken('Bearer', accessToken, expiry.toUtc()),
    null,
    const <String>[kSpeechTokenScope],
  );
}
