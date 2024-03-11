import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SocialIcon extends StatelessWidget {
  final String? iconSrc;
  final Function? press;

  const SocialIcon({
    Key? key,
    this.iconSrc,
    this.press,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: press as void Function()?,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          border: Border.all(
            width: 2,
            color: Theme.of(context).primaryColor,
          ),
          shape: BoxShape.circle,
        ),
        child: SvgPicture.asset(iconSrc!,
            height: size.width * (size.width >= 750 ? 0.035 : 0.04),
            width: size.width * (size.width >= 750 ? 0.035 : 0.04),
            colorFilter: ColorFilter.mode(
              Theme.of(context).colorScheme.onBackground,
              BlendMode.srcIn,
            )),
      ),
    );
  }
}
