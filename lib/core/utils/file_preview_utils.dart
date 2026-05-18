import 'package:mime/mime.dart';

enum FilePreviewKind { pdf, image, text, external }

const previewMaxAutoLoadBytes = 20 * 1024 * 1024;
const previewTextMaxBytes = 512 * 1024;
const previewTextDisplayLimit = 20000;

const _imageExtensions = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'};

const _textExtensions = {
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
  'py',
  'rb',
  'go',
  'rs',
  'kt',
  'swift',
  'c',
  'cpp',
  'h',
  'hpp',
  'csv',
};

String fileExtension(String fileName) {
  final dotIndex = fileName.lastIndexOf('.');
  if (dotIndex == -1 || dotIndex == fileName.length - 1) return '';
  return fileName.substring(dotIndex + 1).toLowerCase();
}

FilePreviewKind getPreviewKind(String fileName) {
  final ext = fileExtension(fileName);
  final mimeType = lookupMimeType(fileName);

  if (ext == 'pdf' || mimeType == 'application/pdf') {
    return FilePreviewKind.pdf;
  }

  if (_imageExtensions.contains(ext) ||
      (mimeType != null && mimeType.startsWith('image/'))) {
    return FilePreviewKind.image;
  }

  if (_textExtensions.contains(ext) ||
      (mimeType != null && mimeType.startsWith('text/'))) {
    return FilePreviewKind.text;
  }

  return FilePreviewKind.external;
}

bool canPreviewInApp(String fileName) {
  return getPreviewKind(fileName) != FilePreviewKind.external;
}
