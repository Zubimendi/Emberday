import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pocketbase/pocketbase.dart';

const defaultApiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://10.0.2.2:8090',
);

class PbClient {
  PbClient({String? baseUrl, FlutterSecureStorage? storage})
      : storage = storage ?? const FlutterSecureStorage(),
        pb = PocketBase(baseUrl ?? defaultApiUrl);

  final PocketBase pb;
  final FlutterSecureStorage storage;

  static const _tokenKey = 'pb_auth_token';

  Future<void> restore() async {
    final token = await storage.read(key: _tokenKey);
    if (token != null && token.isNotEmpty) {
      pb.authStore.save(token, null);
    }
  }

  Future<void> persist() async {
    if (pb.authStore.isValid) {
      await storage.write(key: _tokenKey, value: pb.authStore.token);
    } else {
      await storage.delete(key: _tokenKey);
    }
  }

  Future<void> clear() async {
    pb.authStore.clear();
    await storage.delete(key: _tokenKey);
  }
}
