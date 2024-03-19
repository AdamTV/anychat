// import 'dart:async';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_hooks/flutter_hooks.dart';
// import 'package:rxdart/rxdart.dart';
//
//  mixin DebouncedTextController{
//    static TextEditingController controller = useTextEditingController();
//
//   /// Custom Flutter Hook for a debounced TextEditingController.
//    static TextEditingController useDebouncedTextController(
//       void Function(String) onDebounce) {
//
//     // useEffect is used to subscribe and unsubscribe to the debounced stream.
//     useEffect(() {
//       // Create a BehaviorSubject to handle the debouncing logic.
//       final behaviorSubject = BehaviorSubject<String>();
//       StreamSubscription? streamSubscription;
//
//       // Add a listener to the TextEditingController.
//       controller.addListener(() {
//         // Add the current text value to the BehaviorSubject.
//         behaviorSubject.add(controller.text);
//       });
//
//       // Subscribe to the debounced stream.
//       streamSubscription = behaviorSubject
//           .where((event) => event.length >= 3) // Adjust the minimum length as needed.
//           .debounceTime(const Duration(milliseconds: 500)) // Adjust the debounce time as needed.
//           .distinct()
//           .listen((event) {
//         // Perform the desired action when debounced text changes.
//         onDebounce(event);
//       });
//
//       // Cleanup: Cancel the stream subscription and close the BehaviorSubject.
//       return () {
//         streamSubscription?.cancel();
//         behaviorSubject.close();
//       };
//     }, [controller]); // Re-run the effect when the textController changes.
//
//     // Return the debounced TextEditingController.
//     return controller;
//   }
// }