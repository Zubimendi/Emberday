import 'package:emberday/core/result.dart';
import 'package:emberday/data/api/error_mapper.dart';
import 'package:emberday/data/api/pb_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pbClientProvider = Provider<PbClient>((ref) => PbClient());

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(pbClientProvider));
});

class AuthService {
  AuthService(this._client);

  final PbClient _client;

  Future<Result<String>> signIn(String email, String password) async {
    try {
      final auth = await _client.pb
          .collection('users')
          .authWithPassword(email, password);
      await _client.persist();
      final id = auth.record?.id;
      if (id == null) {
        return Err(mapApiError(StateError('missing record')));
      }
      return Ok(id);
    } on Object catch (e) {
      return Err(mapApiError(e));
    }
  }

  Future<Result<String>> signUp(String email, String password) async {
    try {
      await _client.pb.collection('users').create(body: {
        'email': email,
        'password': password,
        'passwordConfirm': password,
      });
      return signIn(email, password);
    } on Object catch (e) {
      return Err(mapApiError(e));
    }
  }

  Future<void> signOut() async {
    await _client.clear();
  }

  bool get isSignedIn => _client.pb.authStore.isValid;

  String? get userId => _client.pb.authStore.record?.id;
}
