import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:ftpulse/core/imports.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

class UploadEntityModal extends StatefulWidget {
  const UploadEntityModal({super.key});

  @override
  State<UploadEntityModal> createState() => _UploadEntityModalState();
}

class _UploadEntityModalState extends State<UploadEntityModal> {
  bool _isFolderMode = false;

  bool _isLoading = false;
  String? _statusText;

  final List<FileSystemEntity> _selectedEntities = [];

  Future<void> _onPick() async {
    try {
      if (_isFolderMode) {
        if (Platform.isAndroid) {
          if (!await Permission.manageExternalStorage.isGranted) {
            final status = await Permission.manageExternalStorage.request();
            if (!mounted) return;
            if (!status.isGranted) {
              ToastUtils.show(
                context,
                'Permission needed to read folders',
                isError: true,
              );
              return;
            }
          }
        }

        final String? dirPath = await FilePicker.platform.getDirectoryPath();
        if (!mounted) return;
        if (dirPath != null) {
          final dir = Directory(dirPath);

          try {
            final testList = dir.listSync();
            debugPrint('Folder check: Found ${testList.length} items');
            if (testList.isEmpty) {
              ToastUtils.show(
                context,
                'Warning: Folder seems empty or restricted',
                isError: true,
              );
            }
          } catch (e) {
            debugPrint('Access denied: $e');
            ToastUtils.show(
              context,
              'Access denied to this folder',
              isError: true,
            );
            return;
          }

          setState(() {
            _selectedEntities.add(dir);
          });
        }
      } else {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          allowMultiple: true,
        );
        if (!mounted) return;

        if (result != null) {
          final newFiles = result.files
              .where((f) => f.path != null)
              .map((f) => File(f.path!))
              .toList();

          setState(() {
            _selectedEntities.addAll(newFiles);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.show(context, 'Error picking: $e', isError: true);
      }
    }
  }

  Future<void> _onUploadAll() async {
    if (_selectedEntities.isEmpty) return;

    setState(() {
      _isLoading = true;
      _statusText = 'Initializing upload...';
    });

    final provider = context.read<FileBrowserProvider>();

    try {
      int count = 0;
      final total = _selectedEntities.length;

      for (var entity in _selectedEntities) {
        count++;
        final name = p.basename(entity.path);

        setState(() => _statusText = 'Uploading $count/$total: $name');

        if (entity is Directory) {
          await provider.uploadDirectoryRecursive(
            localDirectory: entity,
            onProgress: (fName) {
              if (mounted) {
                setState(
                  () => _statusText = 'Uploading $count/$total: $name ($fName)',
                );
              }
            },
          );
        } else if (entity is File) {
          await provider.uploadFile(entity);
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ToastUtils.show(context, 'All items uploaded successfully');
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.show(context, 'Upload error: $e', isError: true);
        setState(() {
          _isLoading = false;
          _statusText = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: Responsive.modalMaxWidth(context),
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
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
              padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
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
                    'Upload Existing',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (!_isLoading)
                    NeonToggleSwitch(
                      options: const ['File', 'Folder'],
                      selectedIndex: _isFolderMode ? 1 : 0,
                      onChanged: (index) {
                        setState(() => _isFolderMode = index == 1);
                      },
                    ),

                  const SizedBox(height: 24),

                  if (_selectedEntities.isNotEmpty && !_isLoading)
                    Flexible(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(0),
                          itemCount: _selectedEntities.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            color: Colors.white.withOpacity(0.1),
                            indent: 16,
                            endIndent: 16,
                          ),
                          itemBuilder: (context, index) {
                            final entity = _selectedEntities[index];
                            final isDir = entity is Directory;

                            return ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              leading: Icon(
                                isDir
                                    ? CupertinoIcons.folder_solid
                                    : CupertinoIcons.doc_text_fill,
                                color: isDir
                                    ? const Color(0xFFFF9F0A)
                                    : const Color(0xFF00C2FF),
                                size: 20,
                              ),
                              title: Text(
                                p.basename(entity.path),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: SizedBox(
                                width: 30,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(
                                    CupertinoIcons.clear_circled,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() {
                                    _selectedEntities.removeAt(index);
                                  }),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  if (_isLoading)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        children: [
                          NeonLoader(size: 40),
                          const SizedBox(height: 16),
                          Text(
                            _statusText ?? 'Processing...',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_selectedEntities.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Center(
                          child: Text(
                            _isFolderMode
                                ? 'Choose folders to upload'
                                : 'Choose files to upload',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),

                  if (!_isLoading)
                    if (_selectedEntities.isEmpty)
                      NeonButton(
                        text: _isFolderMode ? 'Select Folder' : 'Select Files',
                        isLoading: false,
                        onTap: _onPick,
                      )
                    else
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DarkGlassCard(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            borderRadius: 16,
                            onTap: _onPick,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  CupertinoIcons.add,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isFolderMode ? 'Add Folder' : 'Add Files',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          NeonButton(
                            text: 'Upload All (${_selectedEntities.length})',
                            isLoading: false,
                            onTap: _onUploadAll,
                          ),
                        ],
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
