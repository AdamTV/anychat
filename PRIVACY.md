# Privacy

AnyChat is available on Android, iOS and as a web version. Desktop versions for Windows, Linux and macOS may follow.

- [Matrix](#matrix)
- Sentry
- [Database](#database)
- [Encryption](#encryption)
- [App Permissions](#app-permissions)
- [Push Notifications](#push-notifications)
- [Stories](#stories)

## Matrix<a id="matrix"/>

AnyChat uses the Matrix protocol. This means that AnyChat is just a client that can be connected to any compatible matrix server. The respective data protection agreement of the server selected by the user then applies.

For convenience, one or more servers are set as default that the AnyChat developers consider trustworthy. The developers of AnyChat do not guarantee their trustworthiness. Before the first communication, users are informed which server they are connecting to.

AnyChat only communicates with the selected server, with sentry.io if enabled and with [OpenStreetMap](https://openstreetmap.org) to display maps.

More information is available at: [https://matrix.org](https://matrix.org)

## Database<a id="database"/>

AnyChat caches some data received from the server in a local database on the device of the user.

More information is available at: [https://pub.dev/packages/hive](https://pub.dev/packages/hive)

## Encryption<a id="encryption"/>

All communication of substantive content between Anychat and any server is done in secure way, using transport encryption to protect it.

AnyChat is able to use End-To-End-Encryption as a tech preview.

## App Permissions<a id="app-permissions"/>

The permissions are the same on Android and iOS but may differ in the name. This are the Android Permissions:

#### Internet Access

AnyChat needs to have internet access to communicate with the Matrix Server.

#### Vibrate

AnyChat uses vibration for local notifications. More informations about this are at the used package:
[https://pub.dev/packages/flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)

#### Record Audio

AnyChat can send voice messages in a chat and therefore needs to have the permission to record audio.

#### Write External Storage

The user is able to save received files and therefore app needs this permission.

#### Read External Storage

The user is able to send files from the device's file system.

#### Location

AnyChat makes it possible to share the current location via the chat. When the user shares their location, AnyChat uses the device location service and sends the geo-data via Matrix.

## Push Notifications<a id="push-notifications"/>

AnyChat uses the Firebase Cloud Messaging service for push notifications on Android and iOS. This takes place in the following steps:

1. The matrix server sends the push notification to the AnyChat Push Gateway
2. The AnyChat Push Gateway forwards the message in a different format to Firebase Cloud Messaging
3. Firebase Cloud Messaging waits until the user's device is online again
4. The device receives the push notification from Firebase Cloud Messaging and displays it as a notification

The source code of the push gateway can be viewed here:
[https://gitlab.com/famedly/services/famedly-push-gateway](https://gitlab.com/famedly/services/famedly-push-gateway)

`event_id_only` is used as the format for the push notification. A typical push notification therefore only contains:

- Event ID
- Room ID
- Unread Count
- Information about the device that is to receive the message

A typical push notification could look like this:

```json
{
  "notification": {
    "event_id": "$3957tyerfgewrf384",
    "room_id": "!slw48wfj34rtnrf:example.com",
    "counts": {
      "unread": 2,
      "missed_calls": 1
    },
    "devices": [
      {
        "app_id": "ca.alphatech.anychat",
        "pushkey": "V2h5IG9uIGVhcnRoIGRpZCB5b3UgZGVjb2RlIHRoaXM/",
        "pushkey_ts": 12345678,
        "data": {},
        "tweaks": {
          "sound": "bing"
        }
      }
    ]
  }
}
```

AnyChat sets the `event_id_only` flag at the Matrix Server. This server is then responsible to send the correct data.

## Stories<a id="stories"/>

AnyChat supports stories which is a feature similar to WhatsApp status or Instagram stories. However it is just a different GUI for the same room-related communication. More information about the feature can be found here:

https://github.com/krillefear/matrix-doc/blob/main/proposals/3588-stories-as-rooms.md

Stories are basically:

- End to end encrypted rooms
- Read-only rooms with only one admin who can post stuff (while there is no technical limitation to have multiple admins)

By default:

- The user has to invite all contacts manually to a story room
- The user can only invite contacts (matrix users the user shares a DM room with) to the story room
- The story room is created when the first story is posted
- User can mute and leave story rooms

The user is informed in the app that in theory all contacts can see each other in the story room. The user must give consent here. However the user is at any time able to create a group chat and invite all of their contacts to this chat in any matrix client which has the same result.
