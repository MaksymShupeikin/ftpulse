import 'package:ftpulse/data/models/server_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _key = 'saved_servers';

  Future<void> saveConnections(
    List<ServerConnection> connections,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> jsonList = connections
        .map((e) => e.toJson())
        .toList();
    await prefs.setStringList(_key, jsonList);
  }

  Future<List<ServerConnection>> loadConnections() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? jsonList = prefs.getStringList(_key);

    if (jsonList == null) return [];

    return jsonList.map((e) => ServerConnection.fromJson(e)).toList();
  }
}
