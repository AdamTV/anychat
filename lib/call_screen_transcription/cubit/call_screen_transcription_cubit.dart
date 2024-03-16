import 'package:anychat/main.dart';
import 'package:bloc/bloc.dart';

/// {@template counter_observer}
/// [CallScreenTranscriptionObserver] for the call screen transcription application which
/// observes all state changes.
/// {@endtemplate}
class CallScreenTranscriptionObserver extends BlocObserver {
  /// {@macro counter_observer}
  const CallScreenTranscriptionObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    // ignore: avoid_print
    logger.d('${bloc.runtimeType} $change');
  }
}
