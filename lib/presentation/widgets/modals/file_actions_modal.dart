import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:ftpulse/core/imports.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:share_plus/share_plus.dart';

class FileActionsModal extends StatefulWidget {
  final FileEntity file;

  const FileActionsModal({super.key, required this.file});

  @override
  State<FileActionsModal> createState() => _FileActionsModalState();
}

class _FileActionsModalState extends State<FileActionsModal> {
  static const _imageExts = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'heic',
  ];
  static const _textExts = [
    'txt',
    'md',
    'json',
    'xml',
    'dart',
    'js',
    'css',
    'html',
    'yaml',
    'yml',
    'log',
    'ini',
    'conf',
    'sh',
    'php',
    'sql',
    'gradle',
    'properties',
    'env',
    'gitignore',
    'java',
  ];

  static const _pdfExts = ['pdf'];

  bool _isLoadingPreview = false;
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
    final ext = widget.file.name.split('.').last.toLowerCase();

    final isPreviewable =
        _imageExts.contains(ext) ||
        _textExts.contains(ext) ||
        _pdfExts.contains(ext);

    if (!isPreviewable) return;

    if (mounted) setState(() => _isLoadingPreview = true);

    try {
      final provider = context.read<FileBrowserProvider>();
      final file = await provider.downloadFileForPreview(widget.file);

      if (file != null && mounted) {
        if (_imageExts.contains(ext) || _pdfExts.contains(ext)) {
          setState(() {
            _downloadedFile = file;
            _isLoadingPreview = false;
          });
        } else if (_textExts.contains(ext)) {
          try {
            final content = await file.readAsString();
            setState(() {
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

  Future<void> _onDownloadTap() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      final fileName = widget.file.name;
      final ext = fileName.contains('.') ? fileName.split('.').last : '';

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

      final provider = context.read<FileBrowserProvider>();

      if (_downloadedFile != null) {
        // We already have it from preview
        await _downloadedFile!.copy(exportPath);
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
        fileToShare = await provider.downloadFileForPreview(
          widget.file,
        );
      }
      if (fileToShare != null && mounted) {
        final box = context.findRenderObject() as RenderBox?;
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(fileToShare.path)],
            text: widget.file.name,
            sharePositionOrigin:
                box!.localToGlobal(Offset.zero) & box.size,
          ),
        );
      }
    } catch (e) {
      ToastUtils.show(context, '$e', isError: true);
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

                Expanded(
                  flex: 3,
                  child: _PreviewContent(
                    style: style,
                    isLoading: _isLoadingPreview,
                    downloadedFile: _downloadedFile,
                    textContent: _textContent,
                    fileExtension: widget.file.name.split('.').last,
                  ),
                ),

                const SizedBox(height: 24),

                _FileInfo(file: widget.file),

                const SizedBox(height: 40),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
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
                      icon: CupertinoIcons.pencil,
                      onTap: () {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (dialogContext) => RenameDialog(
                            currentName: widget.file.name,
                            onConfirm: (newName) async {
                              final success = await provider
                                  .renameFile(widget.file, newName);

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
                              final success = await provider
                                  .deleteEntity(widget.file);

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
  final String fileExtension;

  const _PreviewContent({
    required this.style,
    required this.isLoading,
    required this.downloadedFile,
    required this.textContent,
    required this.fileExtension,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (isLoading) {
      content = Center(
        child: NeonLoader(size: 60, color: style.color),
      );
    } else if (downloadedFile != null && fileExtension == 'pdf') {
      content = PDFView(
        filePath: downloadedFile!.path,
        enableSwipe: false,
        swipeHorizontal: true,
        autoSpacing: false,
        pageFling: false,
        pageSnap: false,
        backgroundColor: Colors.transparent,
        fitPolicy: FitPolicy.WIDTH,
        onError: (error) {
          debugPrint(error.toString());
        },
        onPageError: (page, error) {
          debugPrint('$page: ${error.toString()}');
        },
      );
    } else if (downloadedFile != null) {
      content = Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            downloadedFile!,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) =>
                _DefaultIcon(style: style, extension: fileExtension),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
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
      content = _DefaultIcon(style: style, extension: fileExtension);
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: style.color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: style.color.withOpacity(0.2),
          width: 1,
        ),
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
            border: Border.all(
              color: style.color.withOpacity(0.5),
              width: 2,
            ),
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
