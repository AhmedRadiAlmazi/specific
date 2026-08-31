// Real REST Remote Sync API Implementation — مشروع «مُعين» (Mouin)
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mouin/core/config/app_config.dart';
import 'package:mouin/core/errors/failures.dart';
import 'package:mouin/core/result/result.dart';
import 'package:mouin/core/session/session_manager.dart';
import 'package:mouin/infrastructure/sync/sync_engine.dart';

class RemoteSyncApi implements IRemoteSyncApi {
  final String baseUrl;
  final http.Client _client;
  final SessionManager _session;

  RemoteSyncApi({
    String? baseUrl,
    http.Client? client,
    SessionManager? session,
  })  : baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
        _client = client ?? http.Client(),
        _session = session ?? SessionManager();

  // Helper factory for testing / standalone offline verification
  factory RemoteSyncApi.mock() {
    return RemoteSyncApi(
      client: MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/auth/login')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final username = body['username'] ?? 'admin@mouin.app';
          return http.Response(
            jsonEncode({
              'access_token': 'mock_jwt_token_12345',
              'token_type': 'bearer',
              'user': {
                'id': '018e3a2b-0001-7000-8000-000000000001',
                'name': 'مدير النظام (Admin)',
                'email': username,
                'role': 'admin',
                'permissions': ['manage_all', 'items:read', 'items:write', 'debts:read', 'debts:write', 'sync:all'],
              },
              'workspaces': [
                {'id': '018e3a2b-0002-7000-8000-000000000002', 'name': 'مساحة العمل الشخصية', 'role': 'owner'},
                {'id': '018e3a2b-0003-7000-8000-000000000003', 'name': 'مساحة عمل الفريق', 'role': 'admin'}
              ]
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        } else if (path.endsWith('/sync/push')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final ops = body['operations'] as List<dynamic>? ?? [];
          final acks = ops.map((op) => {
            'operation_id': op['operation_id'],
            'status': 'applied',
            'server_sequence': 100,
          }).toList();
          return http.Response(
            jsonEncode({'acks': acks}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        } else if (path.endsWith('/sync/pull')) {
          return http.Response(
            jsonEncode({
              'workspace_id': '018e3a2b-0002-7000-8000-000000000002',
              'changes': [],
              'next_cursor': 1,
              'has_more': false,
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        } else if (path.endsWith('/sync/bootstrap')) {
          return http.Response(
            jsonEncode({
              'workspace_id': '018e3a2b-0002-7000-8000-000000000002',
              'snapshot_items': [],
              'initial_cursor': 1,
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('{"error": "Not Found"}', 404);
      }),
    );
  }

  // Authentication Login
  Future<Result<Map<String, dynamic>, Failure>> login(String username, String password) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/login');
      final res = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(AppConfig.requestTimeout);

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        return Result.success(data);
      } else if (res.statusCode == 401) {
        return const Result.failure(AuthenticationFailure('بيانات الدخول غير صحيحة', 'UNAUTHORIZED'));
      } else {
        return Result.failure(UnknownFailure('فشل المصادقة برمز: ${res.statusCode}', 'AUTH_FAILED'));
      }
    } catch (e) {
      return Result.failure(NetworkFailure('تعذر الاتصال بالخادم: $e', 'NETWORK_ERROR'));
    }
  }

  // Get Current User Profile
  Future<Result<Map<String, dynamic>, Failure>> getMe() async {
    try {
      final uri = Uri.parse('$baseUrl/auth/me');
      final res = await _client.get(
        uri,
        headers: _session.getAuthHeaders(),
      ).timeout(AppConfig.requestTimeout);

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        return Result.success(data);
      } else if (res.statusCode == 401) {
        return const Result.failure(AuthenticationFailure('جلسة الدخول منتهية', 'UNAUTHORIZED'));
      } else {
        return Result.failure(UnknownFailure('فشل جلب الملف الشخصي', 'FETCH_FAILED'));
      }
    } catch (e) {
      return Result.failure(NetworkFailure('خطأ في الشبكة: $e', 'NETWORK_ERROR'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>, Failure>> push(
    String workspaceId,
    List<Map<String, dynamic>> operations,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/sync/push');
      final payload = {
        'client_installation_id': 'flutter-client-${_session.userId.length >= 8 ? _session.userId.substring(0, 8) : "default"}',
        'operations': operations,
      };

      final res = await _client.post(
        uri,
        headers: _session.getAuthHeaders(workspaceId),
        body: jsonEncode(payload),
      ).timeout(AppConfig.requestTimeout);

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        return Result.success(data);
      } else if (res.statusCode == 401) {
        return const Result.failure(AuthenticationFailure('غير مصرح بالدخول', 'UNAUTHORIZED'));
      } else if (res.statusCode == 403) {
        return const Result.failure(AuthorizationFailure('غير مصرح بالوصول لمساحة العمل', 'WORKSPACE_FORBIDDEN'));
      } else if (res.statusCode == 409) {
        return const Result.failure(ConflictFailure('تعارض في معرف العملية', 'IDEMPOTENCY_CONFLICT'));
      } else if (res.statusCode == 422) {
        return const Result.failure(ValidationFailure('خطأ في بنية البيانات المرسلة', 'VALIDATION_ERROR'));
      } else {
        return Result.failure(SyncFailure('فشل الرفع برمز: ${res.statusCode}', 'SYNC_PUSH_FAILED'));
      }
    } catch (e) {
      return Result.failure(NetworkFailure('تعذر الاتصال بالسيرفر أثناء المزامنة: $e', 'NETWORK_ERROR'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>, Failure>> pull(
    String workspaceId,
    int sinceSequence, {
    int limit = 50,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/sync/pull?since_sequence=$sinceSequence&limit=$limit');
      final res = await _client.get(
        uri,
        headers: _session.getAuthHeaders(workspaceId),
      ).timeout(AppConfig.requestTimeout);

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        return Result.success(data);
      } else if (res.statusCode == 401) {
        return const Result.failure(AuthenticationFailure('غير مصرح بالدخول', 'UNAUTHORIZED'));
      } else if (res.statusCode == 403) {
        return const Result.failure(AuthorizationFailure('غير مصرح بالوصول لمساحة العمل', 'WORKSPACE_FORBIDDEN'));
      } else {
        return Result.failure(SyncFailure('فشل الجلب برمز: ${res.statusCode}', 'SYNC_PULL_FAILED'));
      }
    } catch (e) {
      return Result.failure(NetworkFailure('تعذر الاتصال بالسيرفر أثناء جلب التحديثات: $e', 'NETWORK_ERROR'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>, Failure>> bootstrap(String workspaceId) async {
    try {
      final uri = Uri.parse('$baseUrl/sync/bootstrap');
      final res = await _client.get(
        uri,
        headers: _session.getAuthHeaders(workspaceId),
      ).timeout(AppConfig.requestTimeout);

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        return Result.success(data);
      } else if (res.statusCode == 401) {
        return const Result.failure(AuthenticationFailure('غير مصرح بالدخول', 'UNAUTHORIZED'));
      } else if (res.statusCode == 403) {
        return const Result.failure(AuthorizationFailure('غير مصرح بالوصول لمساحة العمل', 'WORKSPACE_FORBIDDEN'));
      } else {
        return Result.failure(SyncFailure('فشل الإقلاع برمز: ${res.statusCode}', 'BOOTSTRAP_FAILED'));
      }
    } catch (e) {
      return Result.failure(NetworkFailure('تعذر الإقلاع الأولي من السيرفر: $e', 'NETWORK_ERROR'));
    }
  }
}
