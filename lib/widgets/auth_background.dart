import 'package:flutter/material.dart';

/// Shared decorative background for the login and register screens: the
/// caller supplies positioned logo images, and the form content is centered
/// on top of them.
class AuthBackground extends StatelessWidget {
  const AuthBackground({
    super.key,
    required this.child,
    required this.images,
  });

  final Widget child;

  /// Positioned background images for the current screen size.
  final List<Widget> Function(Size size) images;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      width: double.infinity,
      height: size.height,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[...images(size), child],
      ),
    );
  }
}
