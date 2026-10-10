import 'package:anychat/components/utilities.dart';
import 'package:anychat/database/anychat_user.dart';
import 'package:flutter/material.dart';

/// Builds the avatar presentation for a user without coupling the data model
/// to Flutter widgets.
Widget buildUserAvatar(AnyChatUser user, {BuildContext? context}) {
  if (user.photoUrl.isNotEmpty) {
    return CircleAvatar(
      backgroundImage: NetworkImage(user.photoUrl),
      backgroundColor: Colors.transparent,
    );
  }

  final avatarContext = context ?? Utilities().globalKey.currentContext!;
  return CircleAvatar(
    backgroundColor: Theme.of(avatarContext).secondaryHeaderColor,
    child: Text(user.displayName.isEmpty ? '?' : user.displayName.characters.first),
  );
}

/// Builds an avatar sized for the participant grid in a conversation row.
Widget buildUserAvatarInContainer(double radius, AnyChatUser user) {
  return Expanded(
    child: SizedBox(
      height: radius,
      width: radius,
      child: user.photoUrl.isEmpty && user.displayName.isEmpty
          ? const CircleAvatar()
          : buildUserAvatar(user),
    ),
  );
}
