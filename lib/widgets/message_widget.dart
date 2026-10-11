import 'package:anychat/components/constants.dart';
import 'package:anychat/database/anychat_auth.dart';
import 'package:anychat/database/anychat_user.dart';
import 'package:flutter/material.dart';

import 'user_avatar.dart';

class MessageWidget extends StatelessWidget {
  final AnyChatUser sender;
  final RichText text;
  final AnimationController animationController;

  const MessageWidget({
    super.key,
    required this.text,
    required this.animationController,
    required this.sender,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = sender.id == AnyChatAuth.currentUser.id;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isCurrentUser
        ? (isDark
            ? kDarkTheme.colorScheme.primaryContainer
            : kLightTheme.colorScheme.primaryContainer)
        : (isDark
            ? kDarkTheme.colorScheme.secondaryContainer
            : kLightTheme.colorScheme.secondaryContainer);

    return SizeTransition(
      sizeFactor: CurvedAnimation(
        parent: animationController,
        curve: Curves.easeOut,
      ),
      axisAlignment: 0,
      child: Align(
        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.all(Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.all(8),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: buildUserAvatar(sender, context: context),
                  ),
                  Text(
                    sender.displayName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8, top: 50),
                    child: Icon(
                      isCurrentUser ? Icons.keyboard : Icons.translate,
                    ),
                  ),
                  Expanded(child: text),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
