import 'package:ftpulse/core/imports.dart';
import 'package:flutter/cupertino.dart';

class RenameDialog extends StatefulWidget {
  final String currentName;
  final bool isFolder;
  final Future<bool> Function(String) onConfirm;

  const RenameDialog({
    super.key,
    required this.currentName,
    required this.onConfirm,
    this.isFolder = false,
  });

  @override
  State<RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<RenameDialog> {
  late TextEditingController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  Future<void> _handleRename() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final newName = _controller.text.trim();
    if (newName.isEmpty || newName == widget.currentName) return;

    setState(() => _isLoading = true);

    final success = await widget.onConfirm(newName);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isFolder ? 'Rename Folder' : 'Rename File';
    final hint = widget.isFolder ? 'Folder Name' : 'Filename';
    final icon = widget.isFolder
        ? CupertinoIcons.folder
        : CupertinoIcons.doc_text;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F1A).withOpacity(0.95),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00C2FF).withOpacity(0.15),
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
                  title,
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

            GlassTextField(
              hint: hint,
              icon: icon,
              controller: _controller,
            ),

            const SizedBox(height: 30),

            NeonButton(
              text: 'Save Changes',
              isLoading: _isLoading,
              onTap: _handleRename,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
