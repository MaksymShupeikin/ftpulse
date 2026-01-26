import 'package:flutter/material.dart';
import 'package:ftpulse/data/models/server_connection.dart';
import 'package:ftpulse/data/services/network_service.dart';
import 'package:uuid/uuid.dart';
import 'package:ftpulse/data/services/storage_service.dart';

class ConnectionsProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  final NetworkService _networkService = NetworkService();

  List<ServerConnection> _connections = [];
  ServerConnection _draft = ServerConnection.empty();
  bool _isTestingConnection = false;
  String? _connectionError;

  List<ServerConnection> get connections => _connections;
  ServerConnection get draft => _draft;
  bool get isTestingConnection => _isTestingConnection;
  String? get connectionError => _connectionError;

  ConnectionsProvider({List<ServerConnection>? initialConnections}) {
    if (initialConnections != null) {
      _connections = initialConnections;
    } else {
      loadData();
    }
  }

  Future<bool> createFromDraft() async {
    return _performConnectAndSave(
      connectionToTest: _draft,
      onSuccess: (validatedConn) {
        final newConnection = validatedConn.copyWith(
          id: const Uuid().v4(),
        );
        _connections.add(newConnection);
        clearDraft();
      },
    );
  }

  Future<bool> updateConnection(ServerConnection updatedData) async {
    return _performConnectAndSave(
      connectionToTest: updatedData,
      onSuccess: (validatedConn) {
        final index = _connections.indexWhere(
          (c) => c.id == validatedConn.id,
        );
        if (index != -1) {
          _connections[index] = validatedConn;
        }
      },
    );
  }

  Future<bool> _performConnectAndSave({
    required ServerConnection connectionToTest,
    required Function(ServerConnection) onSuccess,
  }) async {
    _isTestingConnection = true;
    _connectionError = null;
    notifyListeners();

    try {
      await _networkService.testConnection(connectionToTest);

      onSuccess(connectionToTest);

      await _storageService.saveConnections(_connections);

      _isTestingConnection = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isTestingConnection = false;
      _connectionError = e
          .toString()
          .replaceAll('Exception:', '')
          .trim();
      notifyListeners();
      return false;
    }
  }

  Future<void> loadData() async {
    _connections = await _storageService.loadConnections();
    notifyListeners();
  }

  void updateDraft({
    String? name,
    String? host,
    String? port,
    String? username,
    String? password,
    bool? isSftp,
    bool? useBiometrics,
  }) {
    int? parsedPort;
    if (port != null) {
      parsedPort = int.tryParse(port);
    }

    int? autoPort;
    if (isSftp != null) {
      if (_draft.port == 21 && isSftp) autoPort = 22;
      if (_draft.port == 22 && !isSftp) autoPort = 21;
    }

    _draft = _draft.copyWith(
      name: name,
      host: host?.trim(),
      port: parsedPort ?? autoPort,
      username: username?.trim(),
      password: password?.trim(),
      isSftp: isSftp,
      useBiometrics: useBiometrics,
    );
    notifyListeners();
  }

  void clearDraft() {
    _draft = ServerConnection.empty();
    _connectionError = null;
    notifyListeners();
  }

  Future<void> deleteConnection(String id) async {
    _connections.removeWhere((element) => element.id == id);
    await _storageService.saveConnections(_connections);
    notifyListeners();
  }
}
