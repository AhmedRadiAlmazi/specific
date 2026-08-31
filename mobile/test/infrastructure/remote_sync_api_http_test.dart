import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mouin/core/session/session_manager.dart';
import 'package:mouin/core/errors/failures.dart';
import 'package:mouin/infrastructure/network/remote_sync_api.dart';

void main() {
  group('RemoteSyncApi Real HTTP & Auth Unit Tests', () {
    test('login success parses token, user, and workspaces', () async {
      final client = MockClient((request) async {
        expect(request.url.path, endsWith('/auth/login'));
        final body = jsonDecode(request.body);
        expect(body['username'], equals('admin@mouin.app'));
        return http.Response(
          jsonEncode({
            'access_token': 'test_token_999',
            'token_type': 'bearer',
            'user': {
              'id': '018e3a2b-0001-7000-8000-000000000001',
              'name': 'مدير النظام',
              'email': 'admin@mouin.app',
              'role': 'admin',
              'permissions': ['all'],
            },
            'workspaces': [
              {'id': '018e3a2b-0002-7000-8000-000000000002', 'name': 'مساحة العمل', 'role': 'owner'}
            ]
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final api = RemoteSyncApi(client: client);
      final res = await api.login('admin@mouin.app', 'Password123!');
      expect(res.isSuccess, isTrue);
      expect(res.value['access_token'], equals('test_token_999'));
    });

    test('login with 401 returns AuthenticationFailure', () async {
      final client = MockClient((request) async {
        return http.Response('{"detail": "Invalid credentials"}', 401);
      });

      final api = RemoteSyncApi(client: client);
      final res = await api.login('wrong@mouin.app', 'wrongpass');
      expect(res.isSuccess, isFalse);
      expect(res.failure, isA<AuthenticationFailure>());
    });

    test('push with 403 returns AuthorizationFailure', () async {
      final client = MockClient((request) async {
        return http.Response('{"detail": "Forbidden workspace"}', 403);
      });

      final api = RemoteSyncApi(client: client);
      final res = await api.push('00000000-0000-0000-0000-000000000000', []);
      expect(res.isSuccess, isFalse);
      expect(res.failure, isA<AuthorizationFailure>());
    });

    test('push with 409 returns ConflictFailure', () async {
      final client = MockClient((request) async {
        return http.Response('{"detail": "Conflict"}', 409);
      });

      final api = RemoteSyncApi(client: client);
      final res = await api.push('018e3a2b-0002-7000-8000-000000000002', []);
      expect(res.isSuccess, isFalse);
      expect(res.failure, isA<ConflictFailure>());
    });

    test('network exception returns NetworkFailure', () async {
      final client = MockClient((request) async {
        throw http.ClientException('Connection refused');
      });

      final api = RemoteSyncApi(client: client);
      final res = await api.push('018e3a2b-0002-7000-8000-000000000002', []);
      expect(res.isSuccess, isFalse);
      expect(res.failure, isA<NetworkFailure>());
    });

    test('SessionManager handles authentication state and headers', () {
      final session = SessionManager();
      session.setSession(
        newToken: 'jwt_abc_123',
        newUserId: 'user_1',
        newEmail: 'u@mouin.app',
        newName: 'User One',
        newRole: 'admin',
        newWorkspaces: [{'id': 'ws_1', 'name': 'WS 1', 'role': 'owner'}],
      );

      expect(session.isAuthenticated, isTrue);
      expect(session.userId, equals('user_1'));
      expect(session.activeWorkspaceId, equals('ws_1'));

      final headers = session.getAuthHeaders();
      expect(headers['Authorization'], equals('Bearer jwt_abc_123'));
      expect(headers['x-user-id'], equals('user_1'));
      expect(headers['x-workspace-id'], equals('ws_1'));

      session.clearSession();
      expect(session.isAuthenticated, isFalse);
    });
  });
}
