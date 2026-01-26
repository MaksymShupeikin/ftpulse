import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:ftpulse/core/imports.dart';
import 'package:path_provider/path_provider.dart';

class CreateEntityModal extends StatefulWidget {
  const CreateEntityModal({super.key});

  @override
  State<CreateEntityModal> createState() => _CreateEntityModalState();
}

class _CreateEntityModalState extends State<CreateEntityModal> {
  late TextEditingController _nameController;
  late TextEditingController _extController;

  bool _isFolderMode = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _extController = TextEditingController(text: 'txt');
  }

  Future<void> _onCreate() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final fullName = _isFolderMode
        ? name
        : '$name.${_extController.text.trim()}';

    setState(() => _isLoading = true);
    final provider = context.read<FileBrowserProvider>();

    try {
      bool success = false;
      if (_isFolderMode) {
        success = await provider.createDirectory(fullName);
      } else {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/$fullName');

        await tempFile.writeAsString('');
        success = await provider.uploadFile(tempFile);

        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }

      if (success && mounted) {
        Navigator.pop(context);
        ToastUtils.show(
          context,
          '${_isFolderMode ? "Folder" : "File"} created successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.show(context, 'Error: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(30),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F1A).withOpacity(0.85),
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
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              bottomInset + 20,
            ),
            child: SingleChildScrollView(
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

                  Text(
                    'Create New',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  NeonToggleSwitch(
                    options: const ['Folder', 'File'],
                    selectedIndex: _isFolderMode ? 0 : 1,

                    onChanged: (index) {
                      setState(() {
                        _isFolderMode = index == 0;
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: GlassTextField(
                          controller: _nameController,
                          hint: _isFolderMode
                              ? 'Folder Name'
                              : 'File Name',
                          icon: _isFolderMode
                              ? CupertinoIcons.folder
                              : CupertinoIcons.doc,
                        ),
                      ),

                      if (!_isFolderMode) ...[
                        const SizedBox(width: 8),
                        Text(
                          '.',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: GlassTextField(
                            controller: _extController,
                            hint: 'ext',
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 32),

                  NeonButton(
                    text: _isFolderMode
                        ? 'Create Folder'
                        : 'Create File',
                    isLoading: _isLoading,
                    onTap: _onCreate,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _extController.dispose();
    super.dispose();
  }
}
