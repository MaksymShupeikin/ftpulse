import 'dart:ui';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:ftpulse/core/imports.dart';
import 'package:ftpulse/presentation/pages/file_preview_page.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

class FileActionsModal extends StatefulWidget {
  final FileEntity file;

  const FileActionsModal({super.key, required this.file});

  @override
  State<FileActionsModal> createState() => _FileActionsModalState();
}

class _FileActionsModalState extends State<FileActionsModal> {
  bool _isLoadingPreview = false;
  bool _isOpening = false;
  bool _isSharing = false;
  bool _isDownloading = false;

  File? _downloadedFile;
  String? _textContent;

  @override
  void initState() {
    super.initState();

    _tryLoadPreview();
  }

  Future<void> _tryLoadPreview() async {
    final kind = getPreviewKind(widget.file.name);
    final isPreviewable =
        kind == FilePreviewKind.image || kind == FilePreviewKind.text;

    if (!isPreviewable || widget.file.size > previewMaxAutoLoadBytes) {
      return;
    }

    if (mounted) setState(() => _isLoadingPreview = true);

    try {
      final provider = context.read<FileBrowserProvider>();
      final file = await provider.downloadFileForPreview(widget.file);

      if (file != null && mounted) {
        if (kind == FilePreviewKind.image) {
          setState(() {
            _downloadedFile = file;
            _isLoadingPreview = false;
          });
        } else if (kind == FilePreviewKind.text) {
          try {
            final bytes = await file
                .openRead(0, previewTextMaxBytes)
                .fold<List<int>>([], (buffer, chunk) {
                  buffer.addAll(chunk);
                  return buffer;
                });
            final content = utf8.decode(bytes, allowMalformed: true);
            setState(() {
              _downloadedFile = file;
              _textContent = content.length > 10000
                  ? '${content.substring(0, 10000)}\n\n... (File truncated)'
                  : content;
              _isLoadingPreview = false;
            });
          } catch (e) {
            setState(() => _isLoadingPreview = false);
          }
        }
      } else if (mounted) {
        setState(() => _isLoadingPreview = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPreview = false);
    }
  }

  Future<File?> _ensureDownloaded() async {
    if (_downloadedFile != null) return _downloadedFile;

    final provider = context.read<FileBrowserProvider>();
    final file = await provider.downloadFileForPreview(widget.file);
    if (file != null && mounted) {
      setState(() => _downloadedFile = file);
    }
    return file;
  }

  Future<void> _onPreviewTap() async {
    if (canPreviewInApp(widget.file.name)) {
      final provider = context.read<FileBrowserProvider>();
      await Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: provider,
            child: FilePreviewPage(file: widget.file),
          ),
        ),
      );
      return;
    }

    await _onOpenTap();
  }

  Future<void> _onOpenTap() async {
    if (_isOpening) return;
    setState(() => _isOpening = true);

    try {
      final fileToOpen = await _ensureDownloaded();
      if (fileToOpen == null) {
        if (mounted) {
          ToastUtils.show(context, 'Open failed', isError: true);
        }
        return;
      }

      final result = await OpenFilex.open(fileToOpen.path);
      if (mounted && result.type != ResultType.done) {
        ToastUtils.show(context, result.message, isError: true);
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.show(context, '$e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isOpening = false);
    }
  }

  Future<void> _onDownloadTap() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      final fileName = widget.file.name;
      final provider = context.read<FileBrowserProvider>();

      // Ask for location first
      final exportPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Select download location',
        fileName: fileName,
        type: FileType.any,
      );

      if (exportPath == null) {
        setState(() => _isDownloading = false);
        return;
      }

      final previewFile = _downloadedFile;
      if (previewFile != null) {
        // We already have it from preview
        await previewFile.copy(exportPath);
      } else {
        // Download directly to target
        await provider.downloadEntity(
          entity: widget.file,
          localPath: exportPath,
        );
      }

      if (mounted) {
        ToastUtils.show(context, 'Saved successfully!');
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.show(context, 'Save failed: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _onShareTap() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      File? fileToShare = _downloadedFile;
      if (fileToShare == null) {
        final provider = context.read<FileBrowserProvider>();
        fileToShare = await provider.downloadFileForPreview(widget.file);
      }
      if (fileToShare != null && mounted) {
        final box = context.findRenderObject() as RenderBox?;
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(fileToShare.path)],
            text: widget.file.name,
            sharePositionOrigin: box == null
                ? null
                : box.localToGlobal(Offset.zero) & box.size,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.show(context, '$e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final style = getFileStyle(widget.file);
    final provider = context.read<FileBrowserProvider>();

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: Responsive.modalMaxWidth(context),
          maxHeight: size.height * 0.85,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F1A).withOpacity(0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
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

                    Expanded(
                      flex: 3,
                      child: _PreviewContent(
                        style: style,
                        isLoading: _isLoadingPreview,
                        downloadedFile: _downloadedFile,
                        textContent: _textContent,
                        fileName: widget.file.name,
                        onTap: _onPreviewTap,
                      ),
                    ),

                    const SizedBox(height: 24),

                    _FileInfo(file: widget.file),

                    const SizedBox(height: 40),

                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 18,
                      runSpacing: 16,
                      children: [
                        NeonCircularButton(
                          icon: CupertinoIcons.eye,
                          isLoading: _isOpening,
                          onTap: _onPreviewTap,
                        ),
                        NeonCircularButton(
                          icon: CupertinoIcons.cloud_download,
                          isLoading: _isDownloading,
                          onTap: _onDownloadTap,
                        ),
                        NeonCircularButton(
                          icon: CupertinoIcons.share,
                          isLoading: _isSharing,
                          onTap: _onShareTap,
                        ),
                        NeonCircularButton(
                          icon: CupertinoIcons.arrow_up_right_square,
                          isLoading: _isOpening,
                          onTap: _onOpenTap,
                        ),
                        NeonCircularButton(
                          icon: CupertinoIcons.pencil,
                          onTap: () {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (dialogContext) => RenameDialog(
                                currentName: widget.file.name,
                                onConfirm: (newName) async {
                                  final success = await provider.renameFile(
                                    widget.file,
                                    newName,
                                  );

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
                                title: 'Delete File?',
                                message:
                                    'Are you sure you want to delete "${widget.file.name}"? This cannot be undone.',
                                confirmText: 'Delete Forever',
                                onConfirm: () async {
                                  final success = await provider.deleteEntity(
                                    widget.file,
                                  );

                                  if (success && context.mounted) {
                                    Navigator.of(context).pop();

                                    ToastUtils.show(
                                      context,
                                      'File deleted',
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
        ),
      ),
    );
  }
}

class _PreviewContent extends StatelessWidget {
  final FileStyle style;
  final bool isLoading;
  final File? downloadedFile;
  final String? textContent;
  final String fileName;
  final VoidCallback onTap;

  const _PreviewContent({
    required this.style,
    required this.isLoading,
    required this.downloadedFile,
    required this.textContent,
    required this.fileName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;
    final extension = fileExtension(fileName);
    final kind = getPreviewKind(fileName);

    if (isLoading) {
      content = Center(child: NeonLoader(size: 60, color: style.color));
    } else if (downloadedFile != null && kind == FilePreviewKind.image) {
      content = Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            downloadedFile!,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) =>
                _DefaultIcon(style: style, extension: extension),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
                ),
              ),
            ),
          ),
        ],
      );
    } else if (textContent != null) {
      content = Container(
        color: Colors.black.withOpacity(0.3),
        width: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Text(
            textContent!,
            style: GoogleFonts.poppins(
              color: const Color(0xFF00FF9D),
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ),
      );
    } else {
      content = _DefaultIcon(style: style, extension: extension);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: style.color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: style.color.withOpacity(0.2), width: 1),
            boxShadow: [
              BoxShadow(
                color: style.color.withOpacity(0.1),
                blurRadius: 30,
                spreadRadius: -10,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: content,
          ),
        ),
      ),
    );
  }
}

class _DefaultIcon extends StatelessWidget {
  final FileStyle style;
  final String extension;

  const _DefaultIcon({required this.style, required this.extension});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: style.color.withOpacity(0.1),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: style.color.withOpacity(0.4),
                blurRadius: 40,
                spreadRadius: 0,
              ),
            ],
            border: Border.all(color: style.color.withOpacity(0.5), width: 2),
          ),
          child: Icon(style.icon, size: 80, color: style.color),
        ),
        const SizedBox(height: 24),
        Text(
          extension.toUpperCase(),
          style: GoogleFonts.poppins(
            color: style.color.withOpacity(0.8),
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _FileInfo extends StatelessWidget {
  final FileEntity file;

  const _FileInfo({required this.file});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          file.name,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          getFileSubtitle(file),
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
