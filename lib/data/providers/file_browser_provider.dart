import 'package:ftpulse/core/imports.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FileBrowserProvider extends ChangeNotifier {
  final NetworkService _networkService = NetworkService();
  final ServerConnection connection;

  final Map<String, List<FileEntity>> _cache = {};
  List<FileEntity> _files = [];
  bool _isLoading = true;
  String _currentPath = '/';
  String? _error;

  FileBrowserProvider(this.connection);

  List<FileEntity> get files => _files;
  bool get isLoading => _isLoading;
  String get currentPath => _currentPath;
  String? get error => _error;

  Future<void> init() async {
    _cache.clear();
    await fetchFiles(_currentPath);
  }

  Future<void> fetchFiles(String path, {bool useCache = true}) async {
    _error = null;

    if (useCache && _cache.containsKey(path)) {
      _files = _cache[path]!;
      _currentPath = path;
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _networkService.listFiles(
        connection,
        path,
      );

      if (!_isLoading) {
        debugPrint('Navigation cancelled via Back button');
        return;
      }

      result.removeWhere(
        (element) => element.name == '.' || element.name == '..',
      );

      _sortFilesList(result);

      _cache[path] = result;
      _files = result;
      _currentPath = path;
    } catch (e) {
      if (!_isLoading) return;
      _error = e.toString();
    } finally {
      if (_isLoading) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void _addEntityLocally(FileEntity entity) {
    _files.add(entity);

    _sortFilesList(_files);

    if (_cache.containsKey(_currentPath)) {
      _cache[_currentPath] = List.from(_files);
    }

    notifyListeners();
  }

  void _sortFilesList(List<FileEntity> list) {
    list.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }

  Future<bool> createDirectory(String name) async {
    String fullPath = _currentPath.endsWith('/')
        ? '$_currentPath$name'
        : '$_currentPath/$name';

    try {
      await _networkService.createDirectory(
        connection: connection,
        path: fullPath,
      );

      final newFolder = FileEntity(
        name: name,
        path: fullPath,
        isDirectory: true,
        size: 0,
        modified: DateTime.now(),
      );

      _addEntityLocally(newFolder);

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadFile(File localFile) async {
    try {
      final fileName = localFile.path
          .split(Platform.pathSeparator)
          .last;
      final fileSize = await localFile.length();

      String remotePath = _currentPath.endsWith('/')
          ? '$_currentPath$fileName'
          : '$_currentPath/$fileName';

      await _networkService.uploadFile(
        connection: connection,
        localFile: localFile,
        remotePath: remotePath,
      );

      final newFile = FileEntity(
        name: fileName,
        path: remotePath,
        isDirectory: false,
        size: fileSize,
        modified: DateTime.now(),
      );

      _addEntityLocally(newFile);

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> uploadDirectoryRecursive({
    required Directory localDirectory,
    Function(String)? onProgress,
  }) async {
    final rootFolderName = p.basename(localDirectory.path);

    final created = await createDirectory(rootFolderName);

    if (!created) {
      throw Exception('Failed to create root directory');
    }

    final remoteTargetDir = _currentPath.endsWith('/')
        ? '$_currentPath$rootFolderName'
        : '$_currentPath/$rootFolderName';

    try {
      await _networkService.uploadDirectory(
        connection: connection,
        localDir: localDirectory,
        remoteBaseDir: remoteTargetDir,
        onProgress: onProgress,
      );

    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<File?> downloadFileForPreview(FileEntity file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final safeName = file.name.replaceAll(RegExp(r'[^\w\.-]'), '_');
      final localPath = '${tempDir.path}/${connection.id}_$safeName';
      final localFile = File(localPath);

      if (await localFile.exists()) {
        final stat = await localFile.stat();
        if (stat.size == file.size) {
          debugPrint('Preview cache hit: $localPath');
          return localFile;
        }
      }

      debugPrint('Downloading preview to: $localPath');
      await _networkService.downloadFile(
        connection: connection,
        remotePath: file.path,
        localPath: localPath,
      );

      return localFile;
    } catch (e) {
      debugPrint('Preview download failed: $e');
      return null;
    }
  }

  Future<bool> renameFile(FileEntity file, String newName) async {
    try {
      final parentPath = file.path.substring(
        0,
        file.path.lastIndexOf('/') + 1,
      );
      final newPath = '$parentPath$newName';

      await _networkService.renameFile(
        connection: connection,
        oldPath: file.path,
        newPath: newPath,
      );

      final index = _files.indexWhere(
        (element) => element.path == file.path,
      );

      if (index != -1) {
        final updatedFile = FileEntity(
          name: newName,
          path: newPath,
          size: file.size,
          modified: DateTime.now(),
          isDirectory: file.isDirectory,
        );

        _files[index] = updatedFile;
        _sortFilesList(_files);

        if (_cache.containsKey(_currentPath)) {
          _cache[_currentPath] = List.from(_files);
        }

        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Rename error: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEntity(FileEntity entity) async {
    try {
      await _networkService.deleteEntity(
        connection: connection,
        entity: entity,
      );

      _files.removeWhere((element) => element.path == entity.path);

      if (_cache.containsKey(_currentPath)) {
        _cache[_currentPath]?.removeWhere(
          (element) => element.path == entity.path,
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void navigateTo(FileEntity folder) {
    if (folder.isDirectory) {
      fetchFiles(folder.path);
    }
  }

  bool navigateUp() {
    if (_currentPath == '/' ||
        _currentPath.isEmpty ||
        _currentPath == '.') {
      return false;
    }

    final parent = p.dirname(_currentPath);
    final targetPath = (parent == '.') ? '/' : parent;

    fetchFiles(targetPath);
    return true;
  }

  Future<void> refresh() async {
    _cache.remove(_currentPath);
    await fetchFiles(_currentPath, useCache: false);
  }

  void cancelLoading() {
    if (_isLoading) {
      _isLoading = false;
      _error = null;
      notifyListeners();
    }
  }
}
