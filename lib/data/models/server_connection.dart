import 'dart:convert';

class ServerConnection {
  final String id;
  final String name;
  final String host;
  final int port;
  final String username;
  final String password;
  final bool isSftp;
  final bool useBiometrics;

  ServerConnection({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.username,
    required this.password,
    required this.isSftp,
    required this.useBiometrics,
  });

  factory ServerConnection.empty() {
    return ServerConnection(
      id: '',
      name: '',
      host: '',
      port: 22,
      username: '',
      password: '',
      isSftp: true,
      useBiometrics: false,
    );
  }

  ServerConnection copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    String? username,
    String? password,
    bool? isSftp,
    bool? useBiometrics,
  }) {
    return ServerConnection(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      isSftp: isSftp ?? this.isSftp,
      useBiometrics: useBiometrics ?? this.useBiometrics
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'host': host,
      'port': port,
      'username': username,
      'password': password,
      'isSftp': isSftp,
      'useBiometrics' : useBiometrics,
    };
  }

  factory ServerConnection.fromMap(Map<String, dynamic> map) {
    return ServerConnection(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      host: map['host'] ?? '',
      port: map['port']?.toInt() ?? 22,
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      isSftp: map['isSftp'] ?? true,
      useBiometrics: map['useBiometrics'] ?? true,
    );
  }

  String toJson() => json.encode(toMap());

  factory ServerConnection.fromJson(String source) =>
      ServerConnection.fromMap(json.decode(source));
}
