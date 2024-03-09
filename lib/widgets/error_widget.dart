import 'package:flutter/material.dart';

import 'package:anychat/utils/error_reporter.dart';

class AnyChatErrorWidget extends StatefulWidget {
  final FlutterErrorDetails details;
  const AnyChatErrorWidget(this.details, {super.key});

  @override
  State<AnyChatErrorWidget> createState() => _AnyChatErrorWidgetState();
}

class _AnyChatErrorWidgetState extends State<AnyChatErrorWidget> {
  static final Set<String> knownExceptions = {};
  @override
  void initState() {
    super.initState();

    if (knownExceptions.contains(widget.details.exception.toString())) {
      return;
    }
    knownExceptions.add(widget.details.exception.toString());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ErrorReporter(context, 'Error Widget').onErrorCallback(
        widget.details.exception,
        widget.details.stack,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.orange,
      child: Placeholder(
        child: Center(
          child: Material(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
