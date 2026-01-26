import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:ftpulse/core/imports.dart';

class NeonCircularButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isRed;
  final bool? isLoading;

  const NeonCircularButton({
    super.key,
    required this.onTap,
    this.icon = CupertinoIcons.add,
    this.isRed = false,
    this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final mainColor = isRed
        ? const Color(0xFFFF453A)
        : const Color(0xFF00C2FF);
    final secondaryColor = isRed
        ? const Color(0xFFFF375F)
        : const Color(0xFF0A84FF);

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: mainColor.withOpacity(0.6),
            blurRadius: 20,
            spreadRadius: -5,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  mainColor.withOpacity(0.8),
                  secondaryColor.withOpacity(0.6),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: isLoading != null && isLoading!
                ? NeonLoader(size: 24)
                : Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Haptics.button();
                        onTap();
                      },
                      splashColor: Colors.white.withOpacity(0.3),
                      highlightColor: Colors.white.withOpacity(0.1),
                      child: Center(
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
