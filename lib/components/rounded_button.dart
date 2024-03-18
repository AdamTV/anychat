// import 'package:anychat/components/constants.dart';
// import 'package:flutter/material.dart';
//
// class ElevatedButton extends StatelessWidget {
//   final String? child;
//   final Function? onPressed;
//
//   const ElevatedButton({
//     super.key,
//     this.child,
//     this.onPressed,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     var theme = Theme.of(context);
//     var color = theme.primaryColor;
//     Size size = MediaQuery.of(context).size;
//
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 10),
//       width: size.width * 0.5,
//       constraints: const BoxConstraints(maxWidth: 500),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(29),
//         child: TextButton(
//           style: TextButton.styleFrom(
//             padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
//             backgroundColor: color,
//           ),
//           onPressed: onPressed as void Function()?,
//           child: Text(
//             child!,
//             style: TextStyle(
//                 color: Theme.of(context).primaryColorLight, fontSize: fontSize),
//           ),
//         ),
//       ),
//     );
//   }
// }
