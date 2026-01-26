import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:ftpulse/core/imports.dart';

class FolderActionsModal extends StatelessWidget {
  final FileEntity folder;

  const FolderActionsModal({super.key, required this.folder});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1A).withOpacity(0.9),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(30),
        ),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(30),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 30),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C2FF).withOpacity(0.1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xFF00C2FF,
                        ).withOpacity(0.3),
                        blurRadius: 30,
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFF00C2FF).withOpacity(0.5),
                    ),
                  ),
                  child: const Icon(
                    CupertinoIcons.folder,
                    size: 50,
                    color: Color(0xFF00C2FF),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  folder.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 40),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    NeonCircularButton(
                      icon: CupertinoIcons.pencil,
                      onTap: () {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) => RenameDialog(
                            currentName: folder.name,
                            isFolder: true,
                            onConfirm: (newName) async {
                              final provider = context
                                  .read<FileBrowserProvider>();
                              final success = await provider
                                  .renameFile(folder, newName);

                              if (success && context.mounted) {
                                Navigator.of(context).pop();
                                ToastUtils.show(
                                  context,
                                  'Renamed to $newName',
                                );
                              }
                              return success;
                            },
                          ),
                        );
                      },
                    ),

                    NeonCircularButton(
                      icon: CupertinoIcons.delete,
                      isRed: true,
                      onTap: () {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) => DeleteDialog(
                            title: 'Delete Folder?',
                            message:
                                'Are you sure you want to delete "${folder.name}" and all its contents? This cannot be undone.',
                            confirmText: 'Delete Forever',
                            onConfirm: () async {
                              final provider = context
                                  .read<FileBrowserProvider>();
                              final success = await provider
                                  .deleteEntity(folder);

                              if (success && context.mounted) {
                                Navigator.of(context).pop();
                                ToastUtils.show(
                                  context,
                                  'Folder deleted',
                                  isError: true,
                                );
                              }
                              return success;
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
