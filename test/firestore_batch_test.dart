import 'package:anychat/database/firestore_batch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('chunkForFirestoreInQuery', () {
    test('returns no chunks for an empty input', () {
      expect(chunkForFirestoreInQuery<int>([]), isEmpty);
    });

    test('keeps up to the Firestore whereIn limit in one chunk', () {
      final values = List<int>.generate(firestoreInQueryLimit, (i) => i);

      expect(chunkForFirestoreInQuery(values), [values]);
    });

    test('splits larger inputs without losing or reordering values', () {
      final values =
          List<int>.generate(firestoreInQueryLimit + 1, (i) => i);
      final chunks = chunkForFirestoreInQuery(values);

      expect(chunks.map((chunk) => chunk.length), [30, 1]);
      expect(chunks.expand((chunk) => chunk), values);
    });
  });
}
