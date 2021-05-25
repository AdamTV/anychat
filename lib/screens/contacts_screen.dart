import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/anychat_contact.dart';
import 'package:anychat/components/anychat_user.dart';
import 'package:anychat/components/conversation.dart';
import 'package:anychat/components/rounded_button.dart';
import 'package:anychat/components/utilities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:anychat/components/globals.dart' as globals;

var iOSLocalizedLabels = defaultTargetPlatform == TargetPlatform.iOS;

class ContactsScreen extends StatefulWidget {
  @override
  _ContactsScreenState createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<AnyChatContact> _contacts = [];
  List<AnyChatContact> _filteredContacts = [];

  // controls the text label we use as a search bar
  final TextEditingController _filter = new TextEditingController();

  // final dio = new Dio(); // for http requests
  String _searchText = "";

  // List names = new List(); // names we get from API
  // List _filteredContacts = new List(); // names filtered by search text
  Icon _searchIcon = new Icon(Icons.search);
  Widget _appBarTitle = new Text('');

  _ContactsScreenState() {
    _filter.addListener(() {
      if (_filter.text.isEmpty) {
        setState(() {
          _searchText = "";
          _filteredContacts = _contacts;
          // filteredNames = names;
        });
      } else {
        setState(() {
          _searchText = _filter.text;
        });
      }
    });
  }

  Widget _buildList() {
    if (_searchText.isNotEmpty) {
      List<AnyChatContact> tempList = _filteredContacts.where((element) =>
          element.displayName!
              .toLowerCase()
              .contains(_searchText.toLowerCase())) as List<AnyChatContact>;
      // for (int i = 0; i < _filteredContacts.length; i++) {
      //   if (_filteredContacts[i]
      //       .displayName
      //       .toLowerCase()
      //       .contains(_searchText.toLowerCase())) {
      //     print(_filteredContacts[i].identifier);
      //     tempList.add(_filteredContacts[i]);
      //   }
      // }
      _filteredContacts = tempList;
    }
    var _sortedContacts =
        _filteredContacts.where((element) => element.isRegistered).toList();
    _sortedContacts
        .addAll(_filteredContacts.where((element) => !element.isRegistered));
    return ListView.builder(
      itemCount: _sortedContacts.length,
      itemBuilder: (BuildContext context, int index) {
        AnyChatContact c = _sortedContacts.elementAt(index);
        return contactListTile(c);
      },
    );
    // return ListView.builder(
    //   itemCount: _contacts == null ? 0 : _filteredContacts.length,
    //   itemBuilder: (BuildContext context, int index) {
    //     return new ListTile(
    //       title: Text(_filteredContacts[index].displayName),
    //       onTap: () => print(_filteredContacts[index].displayName),
    //     );
    //   },
    // );
  }

  @override
  void initState() {
    super.initState();
    refreshContacts();
  }

  Future<void> _askPermissions() async {
    PermissionStatus permissionStatus = await _getContactPermission();
    if (permissionStatus != PermissionStatus.granted) {
      _handleInvalidPermissions(permissionStatus);
    }
  }

  Future<PermissionStatus> _getContactPermission() async {
    PermissionStatus permission = await Permission.contacts.status;
    if (permission != PermissionStatus.granted &&
        permission != PermissionStatus.permanentlyDenied) {
      Map<Permission, PermissionStatus> permissionStatus = await [
        Permission.contacts,
      ].request();
      return permissionStatus[Permission.contacts] ?? PermissionStatus.denied;
    } else {
      return permission;
    }
  }

  void _handleInvalidPermissions(PermissionStatus permissionStatus) {
    if (permissionStatus == PermissionStatus.denied) {
      Utilities.showToast(
          AppLocalizations.of(context)!.accessContactDataDisabled);
      // throw PlatformException(
      //     code: AppLocalizations.of(context).permissionDenied,
      //     message: AppLocalizations.of(context).accessContactDataDenied,
      //     details: null);
    } else if (permissionStatus == PermissionStatus.permanentlyDenied) {
      Utilities.showToast(
          AppLocalizations.of(context)!.accessContactDataDisabled);
      // throw PlatformException(
      //     code: AppLocalizations.of(context).permissionDisabled,
      //     message: AppLocalizations.of(context).accessContactDataDisabled,
      //     details: null);
    }
  }

  Future<void> refreshContacts() async {
    setState(() {
      if (_contacts.isNotEmpty) {
        _isLoading = false;
        return;
      }
      _isLoading = true;
    });
    await _askPermissions();

    // Load without thumbnails initially.
    var contacts = (await ContactsService.getContacts(
            withThumbnails: false, iOSLocalizedLabels: iOSLocalizedLabels))
        .toList();
    List<AnyChatContact> list = [];
    for (var contact in contacts) {
      bool isRegistered = false;
      String anyChatId = "";
      // contact.emails.forEach((element) async {
      //   var user = await AnyChatUser.findUserByEmail(element.value);
      //   if (user != null) {
      //     list.add(AnyChatContact(contact, true, user.id));
      //     break;
      //   }
      // });

      // for (var email in contact.emails) {
      //   var user = await AnyChatUser.findUserByEmail(email.value);
      //   if (user != null) {
      //     isRegistered = true;
      //     anyChatId = user.id;
      //     break;
      //   }
      // }
      list.add(AnyChatContact(contact, isRegistered, anyChatId));
    }
//      var contacts = (await ContactsService.getContactsForPhone("8554964652"))
//          .toList();
    setState(() {
      _contacts = list;
      _filteredContacts = _contacts;
      _isLoading = false;
    });

    FirebaseFirestore.instance.collection('users').snapshots().listen((event) {
      event.docs.forEach((element) {
        if (_contacts.any((contact) =>
            contact.emails!.any((email) => email == element['email']))) {
          // _contacts.firstWhere((contact) => contact.emails.firstWhere((email ) => false))
        }
        // allUsersEmails.add(element['email']);
      });
    });

    // Lazy load thumbnails after rendering initial contacts.
    for (int i = 0; i < contacts.length; i++) {
      // contacts[i].emails.forEach((email) async {
      //   AnyChatUser.findUserByEmail(email.value).then((user) => {
      //         if (user != null)
      //           {
      //             setState(() {
      //               _contacts[i].isRegistered = true;
      //               _contacts[i].anyChatId = user.id;
      //             })
      //           }
      //       });
      // });

      ContactsService.getAvatar(contacts[i]).then((avatar) {
        if (avatar == null) return; // Don't redraw if no change.
        setState(() => _contacts[i].avatar = avatar);
      });
    }
  }

  // void updateContact() async {
  //   AnyChatContact ninja = _contacts
  //       .toList()
  //       .firstWhere((contact) => contact.familyName.startsWith("Ninja"));
  //   ninja.avatar = null;
  //   await ContactsService.updateContact(ninja);
  //
  //   refreshContacts();
  // }

  _openContactForm() async {
    try {
      await ContactsService.openContactForm();
      refreshContacts();
    } on FormOperationException catch (e) {
      switch (e.errorCode) {
        case FormOperationErrorCode.FORM_OPERATION_CANCELED:
        case FormOperationErrorCode.FORM_COULD_NOT_BE_OPEN:
        case FormOperationErrorCode.FORM_OPERATION_UNKNOWN_ERROR:
        default:
          print(e.errorCode);
      }
    }
  }

  void _searchPressed() {
    setState(() {
      if (this._searchIcon.icon == Icons.search) {
        this._searchIcon = new Icon(Icons.close);
        this._appBarTitle = new TextField(
          style: TextStyle(
              color: Theme.of(context).primaryColorLight, fontSize: 20),
          autofocus: true,
          controller: _filter,
          decoration: new InputDecoration(
            // contentPadding: EdgeInsets.fromLTRB(20, -10, 20, -10),

            hintStyle: TextStyle(
                color: Theme.of(context).primaryColorLight, fontSize: 20),
            // icon: new Icon(Icons.search),
            hintText: AppLocalizations.of(context)!.searchDotDotDot,
            // border: OutlineInputBorder(),
            border: InputBorder.none,
          ),
        );
      } else {
        this._searchIcon = new Icon(Icons.search);
        this._appBarTitle = new Text(AppLocalizations.of(context)!.yourContacts);
        _filter.clear();
      }
      isSearch = !isSearch;
    });
  }

  late IconButton _backButton;
  var isSearch = false;
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    _backButton = isSearch
        ? IconButton(
            icon: const Icon(Icons.search),
            color: Theme.of(context).primaryColorLight,
            onPressed: () {},
          )
        : IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          );
    if (!isSearch)
      _appBarTitle = new Text(AppLocalizations.of(context)!.yourContacts);
    return Scaffold(
      appBar: AppBar(
        title: _appBarTitle,
        leading: Builder(
          builder: (BuildContext context) {
            return _backButton;
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: _searchIcon,
            onPressed: _searchPressed,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          _openContactForm();
        },
      ),
      // body: _buildList(),
      body: SafeArea(
        child: !_isLoading
            ? _buildList()
            : Center(
                child: CircularProgressIndicator(),
              ),
      ),
    );
  }

  void _launchURL(url) async =>
      await canLaunch(url) ? await launch(url) : throw 'Could not launch $url';

  void contactOnDeviceHasBeenUpdated(AnyChatContact contact) {
    this.setState(() {
      var id = _contacts.indexWhere((c) => c.identifier == contact.identifier);
      _contacts[id] = contact;
    });
  }

  ListTile contactListTile(AnyChatContact c) {
    String sub = c.isRegistered
        ? AppLocalizations.of(context)!.startChatting
        : AppLocalizations.of(context)!.inviteToAnyChat;
    return ListTile(
      onTap: c.isRegistered
          ? () async {
              var user = await AnyChatUser.getUserById(c.anyChatId);
              if (AnyChatAuth.currentConversation == null) {
                var convo = await AnyChatUser.createConversation(user.id);
                if (convo == null) return;
                AnyChatAuth.currentConversation = convo;
                List<AnyChatUser> users = <AnyChatUser>[];
                for (var id in convo.participants) {
                  if (id != AnyChatAuth.currentUser!.id) {
                    users.add(AnyChatUser.fromSnapshot(await FirebaseFirestore
                        .instance
                        .collection('users')
                        .doc(id)
                        .get()));
                  }
                }
                AnyChatAuth.currentChatters = users;
              } else {
                var success = await AnyChatUser.addUserToConversation(user);
                if (success) {
                  AnyChatAuth.currentConversation!.participants.add(user.id);
                  await FirebaseFirestore.instance
                      .runTransaction((Transaction transaction) async {
                    var convoDoc = FirebaseFirestore.instance
                        .collection('conversations')
                        .doc(AnyChatAuth.currentConversation!.id);
                    await transaction
                        .get(convoDoc)
                        .then((DocumentSnapshot doc) =>
                            Conversation.fromSnapshot(doc))
                        .then((Conversation fresh) {
                      transaction.update(convoDoc, {
                        'participants':
                            AnyChatAuth.currentConversation!.participants,
                      });

                      AnyChatAuth.currentChatters.add(user);
                    });
                  });
                }
              }
              Navigator.pushNamed(context, "/chat");
            }
          : () async {
              showDialog(
                  context: context,
                  builder: (BuildContext context) =>
                      _openInviteDialogue(context, c));

              // _launchURL();
              // Navigator.of(context).push(MaterialPageRoute(
              //     builder: (BuildContext context) => FindChatterScreen(email: c.emails.first.toString())));
            },
      leading: (c.avatar != null && c.avatar!.length > 0)
          ? CircleAvatar(backgroundImage: MemoryImage(c.avatar!))
          : CircleAvatar(child: Text(c.initials())),
      title: Text(c.displayName ?? ""),
      subtitle: Text(sub),
    );
  }

  Widget _openInviteDialogue(BuildContext context, Contact user) {
    List<Widget> widgets = [];
    var params =
        "?subject=Let%27s+chat+on+AnyChat%21&body=Let%27s+chat+on+AnyChat%21+It%27s+a+fast%2C+simple+and+secure+app+we+can+use+to+translate+our+messages+and+calls+for+free%21+Get+it+at%3A+https%3A%2F%2Fplay.google.com%2Fstore%2Fapps%2Fdetails%3Fid%3Dca.alphatech.anychat";
    if (user.emails!.isNotEmpty) {
      var eurl =
          "mailto:" + user.emails!.first.value! + params.replaceAll("+", " ");
      widgets.add(RoundedButton(
          text: AppLocalizations.of(context)!.emailInvite,
          press: () {
            _launchURL(eurl);
          }));
    }
    if (user.phones!.isNotEmpty) {
      var purl = "sms:" + user.phones!.first.value! + params;
      widgets.add(RoundedButton(
          text: AppLocalizations.of(context)!.smsInvite,
          press: () {
            _launchURL(purl);
          }));
    }
    return AlertDialog(
        title: Text(AppLocalizations.of(context)!.invite +
            " " +
            user.displayName! +
            " " +
            AppLocalizations.of(context)!.toAnyChat),
        content: new Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widgets));
  }
}
