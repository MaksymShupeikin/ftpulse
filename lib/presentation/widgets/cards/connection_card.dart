import 'package:flutter/cupertino.dart';
import 'package:ftpulse/presentation/widgets/modals/connection_actions_modal.dart';
import '../../../core/imports.dart';

class ConnectionCard extends StatelessWidget {
  final ServerConnection connection;
  final VoidCallback onTap;

  const ConnectionCard({
    super.key,
    required this.connection,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DarkGlassCard(
      width: double.infinity,
      onTap: () async {
        Haptics.selection();

        if (connection.useBiometrics) {
          final authenticated = await BiometricService.authenticate();

          if (!authenticated) {
            Haptics.error();
            return;
          }
          Haptics.success();
        }

        onTap();
      },
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) =>
              ConnectionActionsModal(connection: connection),
        );
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            child: Icon(
              Icons.public,
              color: Colors.cyanAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Hero(
                  tag: 'title_${connection.id}',
                  child: Material(
                    color: Colors.transparent,
                    child: Text(
                      connection.name,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  connection.host,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (connection.useBiometrics)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    CupertinoIcons.lock,
                    color: Color(0xFFFF453A),
                    size: 16,
                  ),
                ),

              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withOpacity(0.2),
                size: 16,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
