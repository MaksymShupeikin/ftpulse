import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class NeonLoader extends StatelessWidget {
  final double size;
  final Color? color;

  const NeonLoader({super.key, this.size = 50.0, this.color});

  @override
  Widget build(BuildContext context) {
    const neonColor = Color(0xFF00C2FF);

    return SpinKitDoubleBounce(
      color: color ?? neonColor,
      size: size,
    );
  }
}
