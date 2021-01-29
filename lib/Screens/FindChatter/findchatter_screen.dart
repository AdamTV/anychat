import 'dart:async';

import 'package:anychat/Screens/FindChatter/components/body.dart';
import 'package:anychat/components/anychat_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FindChatterScreen extends StatefulWidget {
  final String email;

  const FindChatterScreen({Key key, this.email}) : super(key: key);

  @override
  FindChatterScreenState createState() => FindChatterScreenState(email);
}

class FindChatterScreenState extends State<FindChatterScreen> {
  static String email;
  static Stream<QuerySnapshot> searchResults;
  static List<AnyChatUser> users = new List<AnyChatUser>();

  FindChatterScreenState(String email) {
    FindChatterScreenState.email = email;
    loadSearchResults();
    // FindChatterScreen.email = email;
    // FirebaseFirestore.instance.collection('users')
    //     .where('email', isEqualTo: email)
    //     .get()
    //     .then((DocumentSnapshot documentSnapshot) =>
    // {
    //   if()
    // });
    // _currentSubscription = value.listen((event) {
    //   event.docs.map((e) => print("FOUND " + e.data()['email']));
    // })
    // value.forEach((element) {
    //   element.docs.map((e) => {print(e.data()['email'])});
    // })
    // });
    // this._subscription = searchResults.listen((event) {
    //   event.docs.map((DocumentSnapshot doc){
    //     print(doc.data()['email']);
    //   });
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Body(),
    );
  }

  void loadSearchResults() async {
    users.clear();
    await FirebaseFirestore.instance
        .collection('users')
        .get()
        .then((QuerySnapshot querySnapshot) => {
              querySnapshot.docs.forEach((doc) {
                if (doc['email'] == email) {
                  //users.add(AnyChatUser(doc['id'], doc['displayName'], doc['email'], doc['photoUrl']));
                  users.add(AnyChatUser(
                      doc.id,
                      doc["displayName"],
                      doc["email"],
                      doc["photoUrl"],
                      doc["language"],
                      doc['conversations']));
                  print(doc["displayName"]);
                  setState(() {});
                }
              })
            });
  }
}

// class ListDisplay extends StatefulWidget {
//   @override
//   State createState() => new DyanmicList();
// }
//
// class DyanmicList extends State<ListDisplay> {
//   List<String> litems = [];
//   final TextEditingController eCtrl = new TextEditingController();
//
//   @override
//   Widget build(BuildContext ctxt) {
//     return new Scaffold(
//         appBar: new AppBar(
//           title: new Text("Dynamic Demo"),
//         ),
//         body: new Column(
//           children: <Widget>[
//             new TextField(
//               controller: eCtrl,
//               onSubmitted: (text) {
//                 litems.add(text);
//                 eCtrl.clear();
//                 setState(() {});
//               },
//             ),
//             new Expanded(
//                 child: new ListView.builder(
//                     itemCount: litems.length,
//                     itemBuilder: (BuildContext ctxt, int Index) {
//                       return new Text(litems[Index]);
//                     }))
//           ],
//         ));
//   }
// }
