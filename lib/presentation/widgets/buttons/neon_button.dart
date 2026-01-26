import 'dart:ui';
import 'package:ftpulse/core/imports.dart';

class NeonButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool isLoading;
  final bool isRed;

  const NeonButton({
    super.key,
    required this.text,
    required this.onTap,
    this.isRed = false,
    this.isLoading = false,
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
      width: double.infinity,
      height: 55,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
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
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isLoading
                    ? null
                    : () {
                        Haptics.button();
                        onTap();
                      },
                borderRadius: BorderRadius.circular(20),
                splashColor: Colors.white.withOpacity(0.3),
                highlightColor: Colors.white.withOpacity(0.1),
                child: Center(
                  child: isLoading
                      ? NeonLoader(color: Colors.white, size: 24)
                      : Text(
                          text,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
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
