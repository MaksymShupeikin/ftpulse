import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ftpulse/presentation/widgets/buttons/neon_button.dart';

class DeleteDialog extends StatefulWidget {
  final String title;
  final String message;
  final String confirmText;
  final Future<bool> Function() onConfirm;

  const DeleteDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    this.confirmText = 'Delete',
  });

  @override
  State<DeleteDialog> createState() => _DeleteDialogState();
}

class _DeleteDialogState extends State<DeleteDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    const dangerColor = Color(0xFFFF453A);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F1A).withOpacity(0.95),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: dangerColor.withOpacity(0.15),
              blurRadius: 50,
              spreadRadius: -10,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    CupertinoIcons.xmark,
                    color: Colors.white70,
                  ),
                  splashRadius: 20,
                ),
              ],
            ),

            const SizedBox(height: 24),

            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 32),

            NeonButton(
              text: widget.confirmText,
              isLoading: _isLoading,
              isRed: true,
              onTap: () async {
                FocusManager.instance.primaryFocus?.unfocus();
                setState(() => _isLoading = true);
                final success = await widget.onConfirm();
                if (context.mounted) {
                  setState(() => _isLoading = false);
                  if (success) {
                    Navigator.pop(context, true);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
