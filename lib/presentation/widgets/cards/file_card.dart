import 'package:ftpulse/core/imports.dart';

class FileCard extends StatelessWidget {
  final FileEntity file;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const FileCard({
    super.key,
    required this.file,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final FileStyle style = getFileStyle(file);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DarkGlassCard(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        borderRadius: 16,
        onTap: () {
          Haptics.selection();
          onTap();
        },
        onLongPress: () {
          if (onLongPress != null) {
            Haptics.heavy();
            onLongPress!();
          }
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: style.color.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: style.color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(style.icon, color: style.color, size: 24),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    getFileSubtitle(file),
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            if (file.isDirectory)
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withOpacity(0.2),
                size: 14,
              ),
          ],
        ),
      ),
    );
  }
}
