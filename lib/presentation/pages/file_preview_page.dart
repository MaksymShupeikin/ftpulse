import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:ftpulse/core/imports.dart';
import 'package:pdfrx/pdfrx.dart';

class FilePreviewPage extends StatefulWidget {
  final FileEntity file;

  const FilePreviewPage({super.key, required this.file});

  @override
  State<FilePreviewPage> createState() => _FilePreviewPageState();
}

class _FilePreviewPageState extends State<FilePreviewPage> {
  bool _isLoading = true;
  File? _localFile;
  String? _textContent;
  String? _error;

  FilePreviewKind get _kind => getPreviewKind(widget.file.name);

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    if (widget.file.size > previewMaxAutoLoadBytes) {
      setState(() {
        _isLoading = false;
        _error = 'File is too large for quick preview';
      });
      return;
    }

    try {
      final provider = context.read<FileBrowserProvider>();
      final file = await provider.downloadFileForPreview(widget.file);

      if (file == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = 'Preview download failed';
        });
        return;
      }

      String? textContent;
      if (_kind == FilePreviewKind.text) {
        final length = await file.length();
        final bytesToRead = math.min(length, previewTextMaxBytes);
        final bytes = await file.openRead(0, bytesToRead).fold<List<int>>([], (
          buffer,
          chunk,
        ) {
          buffer.addAll(chunk);
          return buffer;
        });
        final content = utf8.decode(bytes, allowMalformed: true);
        final displayContent = content.length > previewTextDisplayLimit
            ? content.substring(0, previewTextDisplayLimit)
            : content;
        textContent =
            length > bytesToRead || content.length > previewTextDisplayLimit
            ? '$displayContent\n\n... (File truncated)'
            : displayContent;
      }

      if (!mounted) return;
      setState(() {
        _localFile = file;
        _textContent = textContent;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = getFileStyle(widget.file);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.file.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          child: _buildBody(style),
        ),
      ),
    );
  }

  Widget _buildBody(FileStyle style) {
    if (_isLoading) {
      return Center(child: NeonLoader(size: 60, color: style.color));
    }

    if (_error != null) {
      return Center(child: ErrorCard(error: _error!));
    }

    final file = _localFile;
    if (file == null) {
      return _FallbackPreview(style: style, fileName: widget.file.name);
    }

    switch (_kind) {
      case FilePreviewKind.pdf:
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: ColoredBox(
            color: Colors.white,
            child: PdfViewer.file(file.path),
          ),
        );
      case FilePreviewKind.image:
        return Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 5,
            child: Image.file(
              file,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) =>
                  _FallbackPreview(style: style, fileName: widget.file.name),
            ),
          ),
        );
      case FilePreviewKind.text:
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.45),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              _textContent ?? '',
              style: GoogleFonts.robotoMono(
                color: const Color(0xFF00FF9D),
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        );
      case FilePreviewKind.external:
        return _FallbackPreview(style: style, fileName: widget.file.name);
    }
  }
}

class _FallbackPreview extends StatelessWidget {
  final FileStyle style;
  final String fileName;

  const _FallbackPreview({required this.style, required this.fileName});

  @override
  Widget build(BuildContext context) {
    final ext = fileExtension(fileName).toUpperCase();

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 96, color: style.color),
          const SizedBox(height: 20),
          Text(
            ext.isEmpty ? 'FILE' : ext,
            style: GoogleFonts.poppins(
              color: style.color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
