import 'package:flutter/material.dart';
import 'package:ftpulse/presentation/widgets/glass_snack_bar.dart';

class ToastUtils {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    final color = isError
        ? const Color(0xFFFF453A)
        : const Color(0xFF32D74B);

    final icon = isError
        ? Icons.error_outline_rounded
        : Icons.check_circle_outline_rounded;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        padding: const EdgeInsets.only(
          bottom: 20,
          left: 16,
          right: 16,
        ),
        duration: const Duration(seconds: 3),
        content: GlassSnackBar(
          message: message,
          color: color,
          icon: icon,
        ),
      ),
    );
  }
}
