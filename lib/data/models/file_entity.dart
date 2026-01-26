class FileEntity {
  final String name;
  final String path;
  final bool isDirectory;
  final int size;
  final DateTime? modified;

  FileEntity({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.size,
    this.modified,
  });
}
