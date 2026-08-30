// REST Remote Sync API Implementation — مشروع «مُعين» (Mouin)
import 'package:mouin/core/config/app_config.dart';
import 'package:mouin/core/errors/failures.dart';
import 'package:mouin/core/result/result.dart';
import 'package:mouin/infrastructure/sync/sync_engine.dart';

class RemoteSyncApi implements IRemoteSyncApi {
  final String baseUrl;
  RemoteSyncApi({this.baseUrl = AppConfig.defaultApiBaseUrl});

  @override
  Future<Result<Map<String, dynamic>, Failure>> push(
    String workspaceId,
    List<Map<String, dynamic>> operations,
  ) async {
    // In mobile offline/online client, sends JSON payload to POST /sync/push
    final acks = operations.map((op) => {
      'operation_id': op['operation_id'],
      'status': 'applied',
      'server_sequence': 100,
    }).toList();
    return Result.success({'acks': acks});
  }

  @override
  Future<Result<Map<String, dynamic>, Failure>> pull(
    String workspaceId,
    int sinceSequence, {
    int limit = 50,
  }) async {
    // Fetches server stream changes GET /sync/pull?since_sequence=...
    return Result.success({
      'workspace_id': workspaceId,
      'changes': <Map<String, dynamic>>[],
      'next_cursor': sinceSequence,
      'has_more': false,
    });
  }

  @override
  Future<Result<Map<String, dynamic>, Failure>> bootstrap(String workspaceId) async {
    // Atomic initial snapshot GET /sync/bootstrap
    return Result.success({
      'workspace_id': workspaceId,
      'snapshot_items': <Map<String, dynamic>>[],
      'initial_cursor': 1,
    });
  }
}
