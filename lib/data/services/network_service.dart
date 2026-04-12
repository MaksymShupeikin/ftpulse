import 'dart:io';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';
import 'package:ftpconnect/ftpconnect.dart';
import 'package:ftpulse/data/models/file_entity.dart';
import 'package:ftpulse/data/models/server_connection.dart';
import 'package:path/path.dart' as p;

class NetworkService {
  Future<void> testConnection(ServerConnection connection) async {
    if (connection.isSftp) {
      await _testSftp(connection);
    } else {
      await _testFtp(connection);
    }
  }

  Future<List<FileEntity>> listFiles(
    ServerConnection connection,
    String path,
  ) async {
    if (connection.isSftp) {
      return _listSftp(connection, path);
    } else {
      return _listFtp(connection, path);
    }
  }

  Future<List<FileEntity>> _listSftp(
    ServerConnection conn,
    String path,
  ) async {
    SSHClient? client;
    try {
      final socket = await SSHSocket.connect(
        conn.host,
        conn.port,
        timeout: const Duration(seconds: 30),
      );
      client = SSHClient(
        socket,
        username: conn.username,
        onPasswordRequest: () => conn.password,
      );
      await client.authenticated;

      final sftp = await client.sftp();
      final items = await sftp.listdir(path);

      client.close();

      return items.map((item) {
        return FileEntity(
          name: item.filename,
          path: path == '/'
              ? '/${item.filename}'
              : '$path/${item.filename}',
          isDirectory: item.attr.isDirectory,
          size: item.attr.size ?? 0,
          modified: item.attr.modifyTime != null
              ? DateTime.fromMillisecondsSinceEpoch(
                  item.attr.modifyTime! * 1000,
                )
              : null,
        );
      }).toList();
    } catch (e) {
      client?.close();
      rethrow;
    }
  }

  Future<List<FileEntity>> _listFtp(
    ServerConnection conn,
    String path,
  ) async {
    final ftpClient = FTPConnect(
      conn.host,
      port: conn.port,
      user: conn.username,
      pass: conn.password,
    );
    try {
      await ftpClient.connect();
      await ftpClient.changeDirectory(path);
      final entries = await ftpClient.listDirectoryContent();
      await ftpClient.disconnect();

      return entries.map((e) {
        return FileEntity(
          name: e.name,
          path: path == '/' ? '/${e.name}' : '$path/${e.name}',
          isDirectory: e.type == FTPEntryType.dir,
          size: e.size ?? 0,
          modified: e.modifyTime,
        );
      }).toList();
    } catch (e) {
      await ftpClient.disconnect();
      rethrow;
    }
  }

  Future<void> _testSftp(ServerConnection connection) async {
    final client = await _connectSsh(connection);
    client.close();
  }

  Future<SSHClient> _connectSsh(ServerConnection connection) async {
    try {
      final socket = await SSHSocket.connect(
        connection.host.trim(),
        connection.port,
        timeout: const Duration(seconds: 20),
      );

      final client = SSHClient(
        socket,
        username: connection.username.trim(),
        onPasswordRequest: () => connection.password,
      );

      await client.authenticated;
      return client;
    } catch (e) {
      if (e.toString().contains('Connection refused')) {
        throw 'Connection refused. Check Host/Port.';
      } else if (e.toString().contains('Authentication failed')) {
        throw 'Wrong Username or Password.';
      }
      rethrow;
    }
  }

  Future<void> _testFtp(ServerConnection connection) async {
    final client = await _connectFtpSmart(connection);
    await client.disconnect();
  }

  Future<FTPConnect> _connectFtpSmart(
    ServerConnection connection,
  ) async {
    final host = connection.host.trim();
    final user = connection.username.trim();
    final pass = connection.password;
    final port = connection.port;

    try {
      final ftpesClient = FTPConnect(
        host,
        port: port,
        user: user,
        pass: pass,
        securityType: SecurityType.ftpes,
        showLog: true,
        timeout: 15,
      );
      await ftpesClient.connect();

      try {
        await ftpesClient.sendCustomCommand('PROT C');
        debugPrint(
          'Switched Data Channel to Plain Text (PROT C) to fix hanging',
        );
      } catch (e) {
        debugPrint('Server rejected PROT C, trying PROT P anyway...');
      }

      return ftpesClient;
    } catch (e) {
      debugPrint("FTPES failed, trying FTPS...");
    }

    try {
      final ftpsClient = FTPConnect(
        host,
        port: port,
        user: user,
        pass: pass,
        securityType: SecurityType.ftps,
        timeout: 15,
      );
      await ftpsClient.connect();

      return ftpsClient;
    } catch (e) {
      debugPrint("FTPS failed, trying Plain FTP...");
    }

    final plainClient = FTPConnect(
      host,
      port: port,
      user: user,
      pass: pass,
      securityType: SecurityType.ftp,
      timeout: 15,
    );

    try {
      await plainClient.connect();
      return plainClient;
    } catch (e) {
      final err = e.toString();
      if (err.contains('530') || err.contains('Login incorrect')) {
        throw 'FTP Login Failed (Error 530). Check login/pass.';
      }
      rethrow;
    }
  }

  Future<File> downloadFile({
    required ServerConnection connection,
    required String remotePath,
    required String localPath,
  }) async {
    if (connection.isSftp) {
      return _downloadSftp(connection, remotePath, localPath);
    } else {
      return _downloadFtp(connection, remotePath, localPath);
    }
  }

  Future<File> _downloadSftp(
    ServerConnection connection,
    String remotePath,
    String localPath,
  ) async {
    final client = await _connectSsh(connection);

    try {
      final sftp = await client.sftp();
      final remoteFile = await sftp.open(remotePath);

      final stat = await sftp.stat(remotePath);

      final stream = remoteFile.read(length: stat.size ?? 0);

      final localFile = File(localPath);

      final sink = localFile.openWrite();

      await sink.addStream(stream);

      await sink.close();
      await remoteFile.close();

      return localFile;
    } finally {
      client.close();
    }
  }

  Future<File> _downloadFtp(
    ServerConnection connection,
    String remotePath,
    String localPath,
  ) async {
    final client = await _connectFtpSmart(connection);

    try {
      final localFile = File(localPath);

      final fileName = remotePath.split('/').last;
      final dirPath = remotePath.substring(
        0,
        remotePath.length - fileName.length,
      );

      if (dirPath.isNotEmpty && dirPath != '/') {
        await client.changeDirectory(dirPath);
      }

      await client.setTransferType(TransferType.binary);

      final exist = await client.existFile(fileName);
      if (!exist) {
        throw Exception('File does not exist on server');
      }

      await client
          .downloadFile(fileName, localFile)
          .timeout(
            const Duration(seconds: 120),
            onTimeout: () {
              throw Exception(
                'Download timed out. Check Firewall/Passive mode.',
              );
            },
          );

      return localFile;
    } catch (e) {
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
      }
      rethrow;
    } finally {
      await client.disconnect();
    }
  }

  Future<void> downloadDirectory({
    required ServerConnection connection,
    required String remotePath,
    required String localPath,
    Function(String)? onProgress,
  }) async {
    if (connection.isSftp) {
      await _downloadDirectorySftp(
        connection,
        remotePath,
        localPath,
        onProgress,
      );
    } else {
      await _downloadDirectoryFtp(
        connection,
        remotePath,
        localPath,
        onProgress,
      );
    }
  }

  Future<void> _downloadDirectorySftp(
    ServerConnection connection,
    String remotePath,
    String localPath,
    Function(String)? onProgress,
  ) async {
    final client = await _connectSsh(connection);
    try {
      final sftp = await client.sftp();

      // Ensure local root dir exists
      final localRootDir = Directory(localPath);
      if (!await localRootDir.exists()) {
        await localRootDir.create(recursive: true);
      }

      await _downloadRecursiveSftp(
        sftp,
        remotePath,
        localPath,
        remotePath,
        onProgress,
      );
    } finally {
      client.close();
    }
  }

  Future<void> _downloadRecursiveSftp(
    SftpClient sftp,
    String remotePath,
    String localBasePath,
    String remoteRootDir,
    Function(String)? onProgress,
  ) async {
    final items = await sftp.listdir(remotePath);

    for (final item in items) {
      if (item.filename == '.' || item.filename == '..') continue;

      final remoteFullPath = remotePath == '/'
          ? '/${item.filename}'
          : '$remotePath/${item.filename}';

      final relativePath = p.relative(remoteFullPath, from: remoteRootDir);
      final localFullPath = p.join(localBasePath, relativePath);

      if (item.attr.isDirectory) {
        await Directory(localFullPath).create(recursive: true);
        await _downloadRecursiveSftp(
          sftp,
          remoteFullPath,
          localBasePath,
          remoteRootDir,
          onProgress,
        );
      } else {
        if (onProgress != null) onProgress(item.filename);

        final remoteFile = await sftp.open(remoteFullPath);
        final stat = await sftp.stat(remoteFullPath);
        final stream = remoteFile.read(length: stat.size ?? 0);

        final localFile = File(localFullPath);
        final sink = localFile.openWrite();
        await sink.addStream(stream);
        await sink.close();
        await remoteFile.close();
      }
    }
  }

  Future<void> _downloadDirectoryFtp(
    ServerConnection connection,
    String remotePath,
    String localPath,
    Function(String)? onProgress,
  ) async {
    final client = await _connectFtpSmart(connection);
    try {
      // Ensure local root dir exists
      final localRootDir = Directory(localPath);
      if (!await localRootDir.exists()) {
        await localRootDir.create(recursive: true);
      }

      await _downloadRecursiveFtp(
        client,
        remotePath,
        localPath,
        remotePath,
        onProgress,
      );
    } finally {
      await client.disconnect();
    }
  }

  Future<void> _downloadRecursiveFtp(
    FTPConnect client,
    String remotePath,
    String localBasePath,
    String remoteRootDir,
    Function(String)? onProgress,
  ) async {
    await client.changeDirectory(remotePath);
    final items = await client.listDirectoryContent();

    for (final item in items) {
      if (item.name == '.' || item.name == '..') continue;

      final remoteFullPath = remotePath == '/'
          ? '/${item.name}'
          : '$remotePath/${item.name}';

      final relativePath = p.relative(remoteFullPath, from: remoteRootDir);
      final localFullPath = p.join(localBasePath, relativePath);

      if (item.type == FTPEntryType.dir) {
        await Directory(localFullPath).create(recursive: true);
        await _downloadRecursiveFtp(
          client,
          remoteFullPath,
          localBasePath,
          remoteRootDir,
          onProgress,
        );
        // Back to current level
        await client.changeDirectory(remotePath);
      } else {
        if (onProgress != null) onProgress(item.name);
        final localFile = File(localFullPath);
        await client.setTransferType(TransferType.binary);
        await client.downloadFile(item.name, localFile);
      }
    }
  }

  Future<void> renameFile({
    required ServerConnection connection,
    required String oldPath,
    required String newPath,
  }) async {
    if (connection.isSftp) {
      await _renameSftp(connection, oldPath, newPath);
    } else {
      await _renameFtp(connection, oldPath, newPath);
    }
  }

  Future<void> _renameSftp(
    ServerConnection connection,
    String oldPath,
    String newPath,
  ) async {
    final client = await _connectSsh(connection);
    try {
      final sftp = await client.sftp();
      await sftp.rename(oldPath, newPath);
    } finally {
      client.close();
    }
  }

  Future<void> _renameFtp(
    ServerConnection connection,
    String oldPath,
    String newPath,
  ) async {
    final client = await _connectFtpSmart(connection);
    try {
      final fileName = oldPath.split('/').last;
      final newName = newPath.split('/').last;
      final dirPath = oldPath.substring(
        0,
        oldPath.length - fileName.length,
      );

      if (dirPath.isNotEmpty && dirPath != '/') {
        await client.changeDirectory(dirPath);
      }

      await client.rename(fileName, newName);
    } finally {
      await client.disconnect();
    }
  }

  Future<void> deleteEntity({
    required ServerConnection connection,
    required FileEntity entity,
  }) async {
    if (connection.isSftp) {
      await _deleteSftp(connection, entity);
    } else {
      await _deleteFtp(connection, entity);
    }
  }

  Future<void> _deleteSftp(
    ServerConnection connection,
    FileEntity entity,
  ) async {
    final client = await _connectSsh(connection);

    try {
      final sftp = await client.sftp();

      if (entity.isDirectory) {
        await _deleteRecursiveSftp(sftp, entity.path);
      } else {
        await sftp.remove(entity.path);
      }
    } finally {
      client.close();
    }
  }

  Future<void> _deleteRecursiveSftp(
    SftpClient sftp,
    String path,
  ) async {
    final items = await sftp.listdir(path);

    for (final item in items) {
      if (item.filename == '.' || item.filename == '..') continue;

      final fullPath = '$path/${item.filename}';

      if (item.attr.isDirectory) {
        await _deleteRecursiveSftp(sftp, fullPath);
      } else {
        await sftp.remove(fullPath);
      }
    }
    await sftp.rmdir(path);
  }

  Future<void> _deleteFtp(
    ServerConnection connection,
    FileEntity entity,
  ) async {
    final client = await _connectFtpSmart(connection);

    try {
      final fileName = entity.path.split('/').last;
      final dirPath = entity.path.substring(
        0,
        entity.path.length - fileName.length,
      );

      if (dirPath.isNotEmpty && dirPath != '/') {
        final ok = await client.changeDirectory(dirPath);
        if (!ok) {
          throw Exception('Cannot change directory to $dirPath');
        }
      } else {
        await client.changeDirectory('/');
      }

      if (entity.isDirectory) {
        await _deleteDirectoryRecursive(client, fileName);
      } else {
        await client.deleteFile(fileName);
      }
    } finally {
      await client.disconnect();
    }
  }

  Future<void> _deleteDirectoryRecursive(
    FTPConnect client,
    String dirName,
  ) async {
    final entered = await client.changeDirectory(dirName);
    if (!entered) {
      throw Exception('Cannot enter directory $dirName');
    }

    final items = await client.listDirectoryContent();

    for (final item in items) {
      switch (item.type) {
        case FTPEntryType.file:
          await client.deleteFile(item.name);
          break;

        case FTPEntryType.dir:
          await _deleteDirectoryRecursive(client, item.name);
          break;

        case FTPEntryType.link:
        case FTPEntryType.unknown:
          break;
      }
    }

    await client.changeDirectory('..');

    final deleted = await client.deleteEmptyDirectory(dirName);
    if (!deleted) {
      throw Exception('Cannot delete directory $dirName');
    }
  }

  Future<void> createDirectory({
    required ServerConnection connection,
    required String path,
  }) async {
    if (connection.isSftp) {
      await _createDirectorySftp(connection, path);
    } else {
      await _createDirectoryFtp(connection, path);
    }
  }

  Future<void> _createDirectorySftp(
    ServerConnection connection,
    String path,
  ) async {
    final client = await _connectSsh(connection);
    try {
      final sftp = await client.sftp();

      try {
        await sftp.mkdir(path);
      } catch (e) {
        debugPrint('SFTP mkdir ignored: $e');
      }
    } finally {
      client.close();
    }
  }

  Future<void> _createDirectoryFtp(
    ServerConnection connection,
    String path,
  ) async {
    final client = await _connectFtpSmart(connection);
    try {
      final parentDir = path.substring(0, path.lastIndexOf('/'));
      final dirName = path.split('/').last;

      if (parentDir.isNotEmpty && parentDir != '/') {
        await client.changeDirectory(parentDir);
      } else {
        await client.changeDirectory('/');
      }

      try {
        await client.makeDirectory(dirName);
      } catch (e) {
        debugPrint('FTP mkdir ignored: $e');
      }
    } finally {
      await client.disconnect();
    }
  }

  Future<void> uploadFile({
    required ServerConnection connection,
    required File localFile,
    required String remotePath,
  }) async {
    if (connection.isSftp) {
      await _uploadFileSftp(connection, localFile, remotePath);
    } else {
      await _uploadFileFtp(connection, localFile, remotePath);
    }
  }

  Future<void> _uploadFileSftp(
    ServerConnection connection,
    File localFile,
    String remotePath,
  ) async {
    final client = await _connectSsh(connection);
    try {
      final sftp = await client.sftp();
      final remoteFile = await sftp.open(
        remotePath,
        mode:
            SftpFileOpenMode.create |
            SftpFileOpenMode.truncate |
            SftpFileOpenMode.write,
      );

      final stream = localFile.openRead().map(
        (chunk) => Uint8List.fromList(chunk),
      );

      await remoteFile.write(stream);
      await remoteFile.close();
    } finally {
      client.close();
    }
  }

  Future<void> _uploadFileFtp(
    ServerConnection connection,
    File localFile,
    String remotePath,
  ) async {
    final client = await _connectFtpSmart(connection);
    try {
      final fileName = remotePath.split('/').last;
      final dirPath = remotePath.substring(
        0,
        remotePath.length - fileName.length,
      );

      if (dirPath.isNotEmpty && dirPath != '/') {
        await client.changeDirectory(dirPath);
      } else {
        await client.changeDirectory('/');
      }

      await client.setTransferType(TransferType.binary);

      await client.uploadFile(localFile);
      final localName = localFile.path
          .split(Platform.pathSeparator)
          .last;
      if (localName != fileName) {
        await client.rename(localName, fileName);
      }
    } finally {
      await client.disconnect();
    }
  }

  Future<void> uploadDirectory({
    required ServerConnection connection,
    required Directory localDir,
    required String remoteBaseDir,
    Function(String)? onProgress,
  }) async {
    if (connection.isSftp) {
      await _uploadDirectorySftp(
        connection,
        localDir,
        remoteBaseDir,
        onProgress,
      );
    } else {
      await _uploadDirectoryFtp(
        connection,
        localDir,
        remoteBaseDir,
        onProgress,
      );
    }
  }

  Future<void> _uploadDirectorySftp(
    ServerConnection connection,
    Directory localDir,
    String remoteBaseDir,
    Function(String)? onProgress,
  ) async {
    final client = await _connectSsh(connection);
    try {
      final sftp = await client.sftp();

      final entities = localDir.listSync(recursive: true);

      entities.sort((a, b) => a.path.length.compareTo(b.path.length));

      for (final entity in entities) {
        String relativePath = p.relative(
          entity.path,
          from: localDir.path,
        );

        relativePath = relativePath.replaceAll('\\', '/');

        final remotePath = remoteBaseDir.endsWith('/')
            ? '$remoteBaseDir$relativePath'
            : '$remoteBaseDir/$relativePath';

        if (entity is Directory) {
          try {
            await _ensureDirectoryExistsSftp(sftp, remotePath);
          } catch (e) {
            debugPrint('Directory create skipped: $e');
          }
        } else if (entity is File) {
          if (onProgress != null) onProgress(relativePath);

          try {
            final parentDir = p
                .dirname(remotePath)
                .replaceAll('\\', '/');
            await _ensureDirectoryExistsSftp(sftp, parentDir);

            final remoteFile = await sftp.open(
              remotePath,
              mode:
                  SftpFileOpenMode.create |
                  SftpFileOpenMode.truncate |
                  SftpFileOpenMode.write,
            );

            final stream = entity.openRead().map(
              (chunk) => Uint8List.fromList(chunk),
            );
            await remoteFile.write(stream);
            await remoteFile.close();
          } catch (e) {
            debugPrint('Failed to upload file $relativePath: $e');
          }
        }
      }
    } finally {
      client.close();
    }
  }

  Future<void> _ensureDirectoryExistsSftp(
    SftpClient sftp,
    String path,
  ) async {
    final parts = path.split('/');
    String currentPath = '';

    for (final part in parts) {
      if (part.isEmpty) continue;
      currentPath += '/$part';

      try {
        await sftp.stat(currentPath);
      } catch (_) {
        try {
          await sftp.mkdir(currentPath);
        } catch (e) {
          debugPrint(e.toString());
        }
      }
    }
  }

  Future<void> _uploadDirectoryFtp(
    ServerConnection connection,
    Directory localDir,
    String remoteBaseDir,
    Function(String)? onProgress,
  ) async {
    final client = await _connectFtpSmart(connection);
    try {
      final entities = localDir.listSync(recursive: true);
      entities.sort((a, b) => a.path.length.compareTo(b.path.length));

      for (final entity in entities) {
        String relativePath = p.relative(
          entity.path,
          from: localDir.path,
        );
        relativePath = relativePath.replaceAll('\\', '/');

        final remotePath = remoteBaseDir.endsWith('/')
            ? '$remoteBaseDir$relativePath'
            : '$remoteBaseDir/$relativePath';

        if (entity is Directory) {
        } else if (entity is File) {
          if (onProgress != null) onProgress(relativePath);

          final parentDir = p
              .dirname(remotePath)
              .replaceAll('\\', '/');

          bool changed = await client.changeDirectory(parentDir);
          if (!changed) {
            await client.makeDirectory(parentDir);
            await client.changeDirectory(parentDir);
          }

          await client.uploadFile(
            entity,
            sRemoteName: p.basename(remotePath),
          );
        }
      }
    } finally {
      await client.disconnect();
    }
  }
}
