import 'package:anychat/components/combined_locale_info.dart';
import 'package:anychat/components/utilities.dart';
import 'package:anychat/database/anychat_auth.dart';
import 'package:anychat/database/anychat_message.dart';
import 'package:anychat/database/anychat_user.dart';
import 'package:anychat/database/conversation.dart';
import 'package:anychat/main.dart';
import 'package:anychat/services/navigation_service.dart';
import 'package:anychat/widgets/user_avatar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class AnyChatConversationWidget {
  List<AnyChatUser> chatters;

  Conversation conversation;

  AnyChatMessage message;

  AnyChatConversationWidget(this.chatters, this.conversation, this.message);

  Slidable getSlidable() {
    logger.d("slidable: ${conversation.id}");
    var timeOfLastMessage = DateTime.fromMillisecondsSinceEpoch(
        conversation.timestamp!.millisecondsSinceEpoch);
    String displayTime = '';
    var difference = DateTime.now().difference(timeOfLastMessage);
    var currentContext = Utilities().globalKey.currentContext;
    if (difference < const Duration(minutes: 1)) {
      displayTime = "< 1 min";
    } else if (difference < const Duration(hours: 1)) {
      displayTime =
          '${difference.inMinutes} ${difference.inMinutes == 1 ? localizationOf(currentContext).minute : localizationOf(currentContext).minutes} ${localizationOf(currentContext).ago}';
    } else if (difference < const Duration(days: 1)) {
      displayTime =
          '${difference.inHours} ${difference.inHours == 1 ? localizationOf(currentContext).hour : localizationOf(currentContext).hours} ${localizationOf(currentContext).ago}';
    } else if (difference < const Duration(days: 7)) {
      displayTime =
          '${difference.inDays} ${difference.inDays == 1 ? localizationOf(currentContext).day : localizationOf(currentContext).days} ${localizationOf(currentContext).ago}';
    } else {
      displayTime =
          '${timeOfLastMessage.year}-${timeOfLastMessage.month}-${timeOfLastMessage.day}';
    }
    return Slidable(
      key: Key(conversation.id),
// actionExtentRatio: 0.25,
// actions: <Widget>[
//   //   new IconSlideAction(
//   //     caption: 'Archive',
//   //     color: Colors.blue,
//   //     icon: Icons.archive,
//   //     onTap: () => logger.d('Archive'),
//   //   ),
//   //   new IconSlideAction(
//   //     caption: 'Share',
//   //     color: Colors.indigo,
//   //     icon: Icons.share,
//   //     onTap: () => logger.d('Share'),
//   //   ),
//   // ],
//   // secondaryActions: <Widget>[
//   //   new IconSlideAction(
//   //     caption: 'More',
//   //     color: Colors.black45,
//   //     icon: Icons.more_horiz,
//   //     onTap: () => logger.d('More'),
//   //   ),
//   IconSlideAction(
//     caption: localizationOf(context).delete,
//     color: Colors.red,
//     icon: Icons.delete,
//     onTap: () => {
//       // setState(() {
//       AnyChatUser.deleteConversation(context, conversation.id)
//       // })
//     },
//   ),
// ],
// startActionPane: SlidableDrawerActionPane(),
      child: Container(
        padding: const EdgeInsets.all(10),
        child: ListTile(
          onTap: () {
// setState(() {
            AnyChatAuth.currentConversation = conversation;
            AnyChatAuth.currentChatters = chatters;
// });
// Navigator.pushNamed(context,  "/chat", arguments: {conversation, chatters});
            NavigationService().pushNamed('/chat');
          },
          leading: getChatterWidgetList(chatters),
// chatters.length > 1
//     ? Icon(Icons.person)
//     : CircleAvatar(
//     backgroundColor: Theme.of(context).primaryColor,
//     backgroundImage: NetworkImage(chatters.first.photoUrl),
//     foregroundColor: Theme.of(context).primaryColorLight),
          title: Text(Utilities().getChatterDisplayNameString(chatters)),
          subtitle: Text(message.text),
          trailing: Text(displayTime),
        ),
      ),
    );
  }
}

Widget getChatterWidgetList(List<AnyChatUser> chatters) {
  const double containerRadius = kIsWeb ? 45 : 55.0;
  const double avatarRadius = containerRadius / 2;
// return Container(
//     height: _containerRadius,
//     width: _containerRadius,
//     decoration: BoxDecoration(
//       shape: BoxShape.circle,
//     ),
//     child: ClipOval(
//       clipBehavior: Clip.antiAlias,
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: <Widget>[
//           Row(
//             children: <Widget>[
//               _buildAvatar(avatarRadius, chatters.first.photoUrl),
//               // _buildAvatar(avatarRadius, Colors.blue),
//               // _buildAvatar(avatarRadius, Colors.black),
//             ],
//           ),
//           // Row(
//           //   children: <Widget>[
//           //     _buildAvatar(avatarRadius, Colors.yellow),
//           //     _buildAvatar(avatarRadius, Colors.red),
//           //     _buildAvatar(avatarRadius, Colors.orange),
//           //   ],
//           // )
//         ],
//       ),
//     ),
// );

  var topWidgets = <Widget>[];
  var bottomWidgets = <Widget>[];
  for (int i = 0; i < chatters.length; i += 2) {
    if (chatters.length < 3) {
      if(chatters.length == 2){
        chatters.removeWhere((element) => element.id == AnyChatAuth.currentUser.id);
      }
        topWidgets
          .add(buildUserAvatarInContainer(containerRadius, chatters[i]));
    }else {
      topWidgets.add(buildUserAvatarInContainer(avatarRadius, chatters[i]));
    }
  }
  for (int i = 1; i < chatters.length; i += 2) {
    bottomWidgets
        .add(buildUserAvatarInContainer(avatarRadius, chatters[i]));
  }
  Column column;
  switch (chatters.length) {
    case 1:
      column = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              children: <Widget>[
                topWidgets.first,
              ],
            )
          ]);
      break;
    case 2:
      column = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            children: <Widget>[topWidgets.first],
          ),
          Row(
            children: <Widget>[
              bottomWidgets.first,
            ],
          )
        ],
      );
      break;
    case 3:
      column = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            children: <Widget>[topWidgets.first, topWidgets[1]],
          ),
          Row(
            children: <Widget>[
              bottomWidgets.first,
            ],
          )
        ],
      );
      break;
    case 4:
      column = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            children: <Widget>[
              topWidgets.first,
              topWidgets[1],
            ],
          ),
          Row(
            children: <Widget>[
              bottomWidgets.first,
              bottomWidgets[1],
            ],
          )
        ],
      );
      break;
    case 5:
      column = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            children: <Widget>[topWidgets.first, topWidgets[1], topWidgets[2]],
          ),
          Row(
            children: <Widget>[
              bottomWidgets.first,
              bottomWidgets[1],
            ],
          )
        ],
      );
      break;
    case 6:
    default:
      column = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            children: <Widget>[topWidgets.first, topWidgets[1], topWidgets[2]],
          ),
          Row(
            children: <Widget>[
              bottomWidgets.first,
              bottomWidgets[1],
              bottomWidgets[2],
            ],
          )
        ],
      );
      break;
  }

  return Container(
      height: containerRadius,
      width: containerRadius,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: ClipOval(clipBehavior: Clip.antiAlias, child: column));

// var widgets = <Positioned>[];
// double top = 1;
// for (var chatter in chatters) {
//   if (chatters.first == chatter) {
//     widgets.add(Positioned(
//       child: new CircleAvatar(
//           backgroundColor: Theme.of(context).primaryColor,
//           backgroundImage: NetworkImage(chatter.photoUrl),
//           foregroundColor: Theme.of(context).primaryColorLight),
//     ));
//   } else {
//     widgets.add(Positioned(
//       top: top,
//       child: new CircleAvatar(
//           backgroundColor: Theme.of(context).primaryColor,
//           backgroundImage: NetworkImage(chatter.photoUrl),
//           foregroundColor: Theme.of(context).primaryColorLight),
//     ));
//     top += 5;
//   }
// }
// return widgets;
}

