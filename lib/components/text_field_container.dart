import 'package:flutter/material.dart';

class TextFieldContainer extends StatelessWidget {
  final Widget? child;

  const TextFieldContainer({
    super.key,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      width: size.width * 0.8,
      constraints: const BoxConstraints(maxWidth: 500),
      decoration: BoxDecoration(
        color: Theme.of(context).focusColor,
        borderRadius: BorderRadius.circular(29),
      ),
      child: child,
    );
  }
}
