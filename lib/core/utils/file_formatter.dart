import 'package:flutter/cupertino.dart';
import 'package:ftpulse/core/imports.dart';

String formatFileSize(int bytes) {
  if (bytes <= 0) return "0 B";
  const suffixes = ["B", "KB", "MB", "GB", "TB"];
  var i = 0;
  double size = bytes.toDouble();
  while (size >= 1024 && i < suffixes.length - 1) {
    size /= 1024;
    i++;
  }
  return '${size.toStringAsFixed(1)} ${suffixes[i]}';
}

FileStyle getFileStyle(FileEntity file) {
  if (file.isDirectory) {
    return FileStyle(
      icon: CupertinoIcons.folder,
      color: const Color(0xFF00C2FF),
    );
  }

  final String extension = file.name.split('.').last.toLowerCase();

  const imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'svg',
    'ico',
    'heic',
  };
  const codeExtensions = {
    'dart',
    'json',
    'xml',
    'html',
    'css',
    'js',
    'yaml',
    'yml',
    'php',
    'py',
    'java',
  };
  const archiveExtensions = {'zip', 'rar', 'tar', 'gz', '7z'};

  if (imageExtensions.contains(extension)) {
    return FileStyle(
      icon: CupertinoIcons.photo,
      color: const Color(0xFFBF5AF2),
    );
  } else if (codeExtensions.contains(extension)) {
    return FileStyle(
      icon: CupertinoIcons.chevron_left_slash_chevron_right,
      color: const Color(0xFF32D74B),
    );
  } else if (archiveExtensions.contains(extension)) {
    return FileStyle(
      icon: CupertinoIcons.archivebox,
      color: const Color(0xFFFF9F0A),
    );
  }

  return FileStyle(
    icon: CupertinoIcons.doc_text,
    color: Colors.white.withOpacity(0.7),
  );
}

String getFileSubtitle(FileEntity file) {
  final List<String> parts = [];

  if (file.isDirectory) {
    parts.add('Folder');
  } else {
    parts.add(formatFileSize(file.size));
  }

  if (file.modified != null) {
    parts.add(formatDate(file.modified!));
  }

  return parts.join(' • ');
}
