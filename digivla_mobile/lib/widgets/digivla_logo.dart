import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Official logo: 1024 × 214 px transparent PNG (with tagline)
const double _logoAspect = 1024 / 214;
const double _iconWidthRatio = 214 / 1024;

/// Full horizontal Digivla logo
class DigivlaLogo extends StatelessWidget {
  const DigivlaLogo({
    super.key,
    this.height,
    this.maxWidth,
  });

  final double? height;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = height ?? (w < 360 ? 40.0 : w < 400 ? 44.0 : 48.0);
    return DigivlaLogoImage(height: h, maxWidth: maxWidth ?? w * 0.88);
  }
}

class DigivlaLogoImage extends StatelessWidget {
  const DigivlaLogoImage({
    super.key,
    required this.height,
    this.maxWidth,
  });

  final double height;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final width = height * _logoAspect;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth ?? width),
      child: Image.asset(
        'assets/logo/digivla_logo.png',
        height: height,
        width: width,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => Text(
          'digivla',
          style: TextStyle(fontSize: height * 0.5, fontWeight: FontWeight.w700, color: AppColors.navy),
        ),
      ),
    );
  }
}

/// Left emblem only — app bar / compact slots
class DigivlaLogoIcon extends StatelessWidget {
  const DigivlaLogoIcon({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: SizedBox(
        width: size,
        height: size,
        child: ClipRect(
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: (_iconWidthRatio * 5.2).clamp(0.15, 0.35),
            child: Image.asset(
              'assets/logo/digivla_logo.png',
              height: size,
              width: size * _logoAspect,
              fit: BoxFit.cover,
              alignment: Alignment.centerLeft,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }
}
