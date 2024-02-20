import 'dart:async';

extension StreamRepeatLatestExtension<T extends Object> on Stream<T> {
  Stream<T> repeatLatest() {
    var done = false;
    T? latest;
    var currentListeners = <MultiStreamController<T>>{};
    listen((event) {
      latest = event;
      for (var listener in [...currentListeners]) {
        listener.addSync(event);
      }
    }, onError: (Object error, StackTrace stack) {
      for (var listener in [...currentListeners]) {
        listener.addErrorSync(error, stack);
      }
    }, onDone: () {
      done = true;
      latest = null;
      for (var listener in currentListeners) {
        listener.closeSync();
      }
      currentListeners.clear();
    });
    return Stream.multi((controller) {
      if (done) {
        controller.close();
        return;
      }
      currentListeners.add(controller);
      var latestValue = latest;
      if (latestValue != null) controller.add(latestValue);
      controller.onCancel = () {
        currentListeners.remove(controller);
      };
    });
  }
}