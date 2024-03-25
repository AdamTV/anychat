// class NotificationManager {
//   // Private constructor
//   NotificationManager._privateConstructor();
//
//   // Static instance
//   static final NotificationManager _instance =
//       NotificationManager._privateConstructor();
//
//   // Factory constructor to return the same instance
//   factory NotificationManager() {
//     return _instance;
//   }
//
//   // Listeners list
//   final List<Function(String)> _listeners = [];
//
//   // Subscribe method
//   void subscribe(Function(String) callback) {
//     _listeners.add(callback);
//   }
//
//   // Unsubscribe method
//   void unsubscribe(Function(String) callback) {
//     _listeners.remove(callback);
//   }
//
//   // Dispatch method
//   void dispatch(String notification) {
//     for (var listener in _listeners) {
//       listener(notification);
//     }
//   }
// }
