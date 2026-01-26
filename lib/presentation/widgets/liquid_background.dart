import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

class LiquidBackground extends StatefulWidget {
  const LiquidBackground({super.key});

  @override
  State<LiquidBackground> createState() => _LiquidBackgroundState();
}

class _LiquidBackgroundState extends State<LiquidBackground> {
  Alignment _blob1Align = const Alignment(-1.0, -1.0);
  Alignment _blob2Align = const Alignment(1.0, 0.3);
  Alignment _blob3Align = const Alignment(-0.5, 1.0);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      _startAnimationLoop();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAnimationLoop() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      setState(() {
        _blob1Align = Alignment(
          -1.0 + (0.5 * (timer.tick % 2 == 0 ? 1 : 0.2)),
          -1.0 + (0.5 * (timer.tick % 3 == 0 ? 1 : 0.1)),
        );
        _blob2Align = Alignment(
          1.0 - (0.4 * (timer.tick % 2 != 0 ? 1 : 0.1)),
          0.0 + (0.6 * (timer.tick % 3 != 0 ? 1 : -1)),
        );
        _blob3Align = Alignment(
          0.0 + (0.8 * (timer.tick % 2 == 0 ? -1 : 1)),
          1.0 - (0.3 * (timer.tick % 3 == 0 ? 1 : 0.2)),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(seconds: 4),
            curve: Curves.easeInOutSine,
            alignment: _blob1Align,
            child: _buildBlob(const Color(0xFF0A84FF), 350),
          ),
          AnimatedAlign(
            duration: const Duration(seconds: 4),
            curve: Curves.easeInOutSine,
            alignment: _blob2Align,
            child: _buildBlob(Colors.purpleAccent, 300),
          ),
          AnimatedAlign(
            duration: const Duration(seconds: 4),
            curve: Curves.easeInOutSine,
            alignment: _blob3Align,
            child: _buildBlob(Colors.cyanAccent, 300),
          ),

          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
            child: Container(color: Colors.transparent),
          ),

          Container(color: Colors.black.withOpacity(0.6)),

          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.6),
        shape: BoxShape.circle,
      ),
    );
  }
}
