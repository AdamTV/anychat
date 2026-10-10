/// Firestore `whereIn` queries accept at most 30 document IDs per request.
const firestoreInQueryLimit = 30;

/// Splits [values] into Firestore-compatible `whereIn` chunks.
List<List<T>> chunkForFirestoreInQuery<T>(Iterable<T> values) {
  final items = values.toList(growable: false);
  final chunks = <List<T>>[];
  for (var start = 0; start < items.length; start += firestoreInQueryLimit) {
    final end = start + firestoreInQueryLimit < items.length
        ? start + firestoreInQueryLimit
        : items.length;
    chunks.add(items.sublist(start, end));
  }
  return chunks;
}
