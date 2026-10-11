import 'package:anychat/services/speech_credentials.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validPayload = <String, dynamic>{
    'accessToken': 'token-1',
    'tokenType': 'Bearer',
    'expirationTime': '2026-01-01T00:00:00.000Z',
  };

  test('maps a valid payload into bearer credentials', () {
    final credentials = speechCredentialsFromCallableResult(validPayload);

    expect(credentials.accessToken.type, 'Bearer');
    expect(credentials.accessToken.data, 'token-1');
    expect(credentials.accessToken.expiry, DateTime.utc(2026, 1, 1));
    expect(credentials.refreshToken, isNull);
    expect(credentials.idToken, isNull);
    expect(credentials.scopes, <String>[kSpeechTokenScope]);
  });

  test('rejects payloads that are not a map', () {
    expect(
      () => speechCredentialsFromCallableResult('nope'),
      throwsFormatException,
    );
  });

  test('rejects payloads without an accessToken', () {
    expect(
      () => speechCredentialsFromCallableResult(
        <String, dynamic>{'tokenType': 'Bearer'},
      ),
      throwsFormatException,
    );
  });

  test('rejects empty access tokens', () {
    expect(
      () => speechCredentialsFromCallableResult(
        <String, dynamic>{...validPayload, 'accessToken': ''},
      ),
      throwsFormatException,
    );
  });

  test('rejects non-bearer tokens', () {
    expect(
      () => speechCredentialsFromCallableResult(
        <String, dynamic>{...validPayload, 'tokenType': 'Basic'},
      ),
      throwsFormatException,
    );
  });

  test('rejects payloads without an expirationTime', () {
    expect(
      () => speechCredentialsFromCallableResult(
        <String, dynamic>{...validPayload, 'expirationTime': null},
      ),
      throwsFormatException,
    );
  });

  test('rejects an unparseable expirationTime', () {
    expect(
      () => speechCredentialsFromCallableResult(
        <String, dynamic>{...validPayload, 'expirationTime': 'not-a-date'},
      ),
      throwsFormatException,
    );
  });
}
