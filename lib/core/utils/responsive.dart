import 'dart:math';
import 'package:flutter/widgets.dart';

class Responsive {
  static const double _maxContent = 680.0;
  static const double _smallBreak = 360.0;
  static const double _desktopBreak = 600.0;
  static const double _modalMaxWidth = 560.0;

  static bool isSmall(BuildContext context) =>
      MediaQuery.of(context).size.width < _smallBreak;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= _desktopBreak;

  /// Horizontal padding for list content.
  /// Centers content at [_maxContent] on wide screens; tightens on very small ones.
  static double listHPad(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= _desktopBreak) {
      return max(24.0, (w - _maxContent) / 2);
    }
    return w < _smallBreak ? 8.0 : 16.0;
  }

  /// Max width for modal bottom sheets on wide screens.
  static double modalMaxWidth(BuildContext context) =>
      min(_modalMaxWidth, MediaQuery.of(context).size.width);
}
