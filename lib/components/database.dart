// // Copyright 2019 The Chromium Authors. All rights reserved.
// // Use of this source code is governed by a BSD-style license that can be
// // found in the LICENSE file.
//
// import 'dart:async';
// import 'dart:io' show Platform;
//
// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:firebase_database/ui/firebase_animated_list.dart';
// import 'package:cloud_functions/cloud_functions.dart';
//
// Future<void> getFruit() async {
//   HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('pushNotification');
//   final results = await callable();
//   print(results);
//   print('test fruit');
//   List fruit = results.data;  // ["Apple", "Banana", "Cherry", "Date", "Fig", "Grapes"]
//   print(fruit);
// }
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   final FirebaseApp app = await Firebase.initializeApp(
//     name: 'db2',
//     options: Platform.isIOS || Platform.isMacOS
//         ? FirebaseOptions(
//       appId: '1:682283241991:ios:f05d7495c93fd781abd0a2',
//       apiKey: 'AIzaSyDHVwxcshXvU9HtkM_Kk3uYcTsWHnDSLmM',
//       projectId: 'anychat-c414a',
//       messagingSenderId: '297855924061',
//       databaseURL: 'https://anychat-c414a-default-rtdb.firebaseio.com',
//     )
//         : FirebaseOptions(
//       appId: '1:682283241991:android:2e4d2787e4712822abd0a2',
//       apiKey: 'AIzaSyDHVwxcshXvU9HtkM_Kk3uYcTsWHnDSLmM',
//       messagingSenderId: '297855924061',
//       projectId: 'anychat-c414as',
//       databaseURL: 'https://anychat-c414a-default-rtdb.firebaseio.com',
//     ),
//   );
//   getFruit();
//   runApp(MaterialApp(
//     title: 'Flutter Database Example',
//     home: MyHomePage(app: app),
//   ));
// }
//
// class MyHomePage extends StatefulWidget {
//   MyHomePage({this.app});
//   final FirebaseApp app;
//
//   @override
//   _MyHomePageState createState() => _MyHomePageState();
// }
//
// class _MyHomePageState extends State<MyHomePage> {
//   int _counter;
//   DatabaseReference _counterRef;
//   DatabaseReference _messagesRef;
//   StreamSubscription<Event> _counterSubscription;
//   StreamSubscription<Event> _messagesSubscription;
//   bool _anchorToBottom = false;
//
//   String _kTestKey = 'Hello';
//   String _kTestValue = 'world!';
//   DatabaseError _error;
//
//   @override
//   void initState() {
//     super.initState();
//     // Demonstrates configuring to the database using a file
//     _counterRef = FirebaseDatabase.instance.reference().child('counter');
//     // Demonstrates configuring the database directly
//     final FirebaseDatabase database = FirebaseDatabase(app: widget.app);
//     _messagesRef = database.reference().child('messages');
//     database.reference().child('counter').once().then((DataSnapshot snapshot) {
//       print('Connected to second database and read ${snapshot.value}');
//     });
//     database.setPersistenceEnabled(true);
//     database.setPersistenceCacheSizeBytes(10000000);
//     _counterRef.keepSynced(true);
//     _counterSubscription = _counterRef.onValue.listen((Event event) {
//       setState(() {
//         _error = null;
//         _counter = event.snapshot.value ?? 0;
//       });
//     }, onError: (Object o) {
//       final DatabaseError error = o;
//       setState(() {
//         _error = error;
//       });
//     });
//     _messagesSubscription =
//         _messagesRef.limitToLast(10).onChildAdded.listen((Event event) {
//           print('Child added: ${event.snapshot.value}');
//         }, onError: (Object o) {
//           final DatabaseError error = o;
//           print('Error: ${error.code} ${error.message}');
//         });
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//     _messagesSubscription.cancel();
//     _counterSubscription.cancel();
//   }
//
//   Future<void> _increment() async {
//     // Increment counter in transaction.
//     final TransactionResult transactionResult =
//     await _counterRef.runTransaction((MutableData mutableData) async {
//       mutableData.value = (mutableData.value ?? 0) + 1;
//       return mutableData;
//     });
//
//     if (transactionResult.committed) {
//       _messagesRef.push().set(<String, String>{
//         _kTestKey: '$_kTestValue ${transactionResult.dataSnapshot.value}'
//       });
//     } else {
//       print('Transaction not committed.');
//       if (transactionResult.error != null) {
//         print(transactionResult.error.message);
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Flutter Database Example'),
//       ),
//       body: Column(
//         children: <Widget>[
//           Flexible(
//             child: Center(
//               child: _error == null
//                   ? Text(
//                 'Button tapped $_counter time${_counter == 1 ? '' : 's'}.\n\n'
//                     'This includes all devices, ever.',
//               )
//                   : Text(
//                 'Error retrieving button tap count:\n${_error.message}',
//               ),
//             ),
//           ),
//           ListTile(
//             leading: Checkbox(
//               onChanged: (bool value) {
//                 setState(() {
//                   _anchorToBottom = value;
//                 });
//               },
//               value: _anchorToBottom,
//             ),
//             title: const Text('Anchor to bottom'),
//           ),
//           Flexible(
//             child: FirebaseAnimatedList(
//               key: ValueKey<bool>(_anchorToBottom),
//               query: _messagesRef,
//               reverse: _anchorToBottom,
//               sort: _anchorToBottom
//                   ? (DataSnapshot a, DataSnapshot b) => b.key.compareTo(a.key)
//                   : null,
//               itemBuilder: (BuildContext context, DataSnapshot snapshot,
//                   Animation<double> animation, int index) {
//                 return SizeTransition(
//                   sizeFactor: animation,
//                   child: ListTile(
//                     trailing: IconButton(
//                       onPressed: () =>
//                           _messagesRef.child(snapshot.key).remove(),
//                       icon: Icon(Icons.delete),
//                     ),
//                     title: Text(
//                       "$index: ${snapshot.value.toString()}",
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _increment,
//         tooltip: 'Increment',
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
// }