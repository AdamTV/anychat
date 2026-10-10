import 'package:flutter/material.dart';

import 'package:anychat/components/combined_locale_info.dart';

/// One tappable entry shown in the shared app drawer.
class AnyChatDrawerEntry {
  const AnyChatDrawerEntry({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;
}

/// Drawer shared by the chat, conversations, and live translator screens so
/// the header and entry styling stay identical everywhere.
class AnyChatDrawer extends StatelessWidget {
  const AnyChatDrawer({super.key, required this.entries});

  final List<AnyChatDrawerEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      // Add a ListView to the drawer. This ensures the user can scroll
      // through the options in the drawer if there isn't enough vertical
      // space to fit everything.
      child: ListView(
        // Important: Remove any padding from the ListView.
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Text(
              localizationOf(context).title,
              style: TextStyle(color: Theme.of(context).primaryColorLight),
            ),
          ),
          for (final entry in entries)
            ListTile(
              title: Text(entry.title),
              onTap: entry.onTap,
            ),
        ],
      ),
    );
  }
}
