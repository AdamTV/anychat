
sealed class CallScreenTranscriptionEvent {}

final class CallScreenAudioRecieved extends CallScreenTranscriptionEvent {}
final class CallScreenARecieved extends CallScreenTranscriptionEvent {}

// class CallScreenBloc
//     extends Bloc<CallScreenTranscriptionEvent, QuerySnapshot> {
//   CallScreenBloc() : super();
//   on<CallScreenAudioRecieved>((event, emit)) {
//     // handle local audio
//   }
// }
