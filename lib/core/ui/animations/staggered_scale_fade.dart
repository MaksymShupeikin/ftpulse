import 'package:ftpulse/core/imports.dart';

class StaggeredScaleFade extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  final double intervalStart;
  final double intervalEnd;

  const StaggeredScaleFade({
    super.key,
    required this.child,
    required this.animation,
    this.intervalStart = 0.0,
    this.intervalEnd = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final curvedValue = CurvedAnimation(
          parent: animation,
          curve: Interval(
            intervalStart,
            intervalEnd,
            curve: Curves.elasticOut,
          ),
          reverseCurve: Interval(
            intervalStart,
            intervalEnd,
            curve: Curves.easeOut,
          ),
        );

        return Transform.scale(
          scale: curvedValue.value,
          child: Opacity(

            opacity: curvedValue.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
