import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Set with `--dart-define=ANYCHAT_USE_EMULATORS=true` to run the app against
/// the local Firebase emulators (acceptance tests). Release builds never set it.
const bool useFirebaseEmulators = bool.fromEnvironment('ANYCHAT_USE_EMULATORS');

/// Emulator host as seen from the device; 10.0.2.2 is the Android emulator's
/// alias for the host machine.
const String firebaseEmulatorHost =
    String.fromEnvironment('ANYCHAT_EMULATOR_HOST', defaultValue: '10.0.2.2');

const int authEmulatorPort = 9099;
const int firestoreEmulatorPort = 8181;
const int functionsEmulatorPort = 5001;

/// Points Auth, Firestore and Functions at the emulators. Must run after
/// Firebase.initializeApp and before any Firebase call.
Future<void> connectFirebaseEmulators() async {
  await FirebaseAuth.instance
      .useAuthEmulator(firebaseEmulatorHost, authEmulatorPort);
  FirebaseFirestore.instance
      .useFirestoreEmulator(firebaseEmulatorHost, firestoreEmulatorPort);
  FirebaseFunctions.instance
      .useFunctionsEmulator(firebaseEmulatorHost, functionsEmulatorPort);
}
