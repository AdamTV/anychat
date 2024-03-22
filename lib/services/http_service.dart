import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;


Future<String> agoraAuth() async {
  final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
  final uid = AnyChatAuth.currentUser!.id.hashCode;
  final channelName = AnyChatAuth.currentConversation?.id;
  final response = await http.get(
    Uri.parse(
        'https://us-central1-anychat-c414a.cloudfunctions.net/agora-auth?uid=$uid&channelName=$channelName'),
    // Include the ID token in the Authorization header
    headers: {
      'Authorization': 'Bearer $idToken',
    },
  );

  if (response.statusCode == 200) {
    // Process the response
    logger.d('Success: ${response.body}');
    return response.body;
  } else {
    // Handle errors
    logger.e('Backend call failed: ${response.statusCode}');
    return '';
  }
}
