import 'package:emberday/app_providers.dart';
import 'package:emberday/data/api/auth.dart';
import 'package:emberday/data/sync/engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SyncUiStatus {
  hidden,
  offline,
  syncing,
  issue,
  pending,
  upToDate,
}

extension SyncUiStatusX on SyncUiStatus {
  String get label => switch (this) {
        SyncUiStatus.hidden => '',
        SyncUiStatus.offline => 'Offline',
        SyncUiStatus.syncing => 'Syncing',
        SyncUiStatus.issue => 'Issue',
        SyncUiStatus.pending => 'Pending',
        SyncUiStatus.upToDate => 'Up to date',
      };
}

final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine(
    database: ref.watch(databaseProvider),
    settings: ref.watch(settingsRepositoryProvider),
    outbox: ref.watch(outboxRepositoryProvider),
    clock: ref.watch(clockProvider),
    logger: ref.watch(loggerProvider),
    pbClient: ref.watch(pbClientProvider),
  );
});

final syncStatusProvider = Provider<SyncUiStatus>((ref) {
  final settings = ref.watch(settingsMapProvider).value ?? {};
  if (settings['has_session'] != 'true') return SyncUiStatus.hidden;
  final state = settings['sync_ui'] ?? 'up_to_date';
  return switch (state) {
    'offline' => SyncUiStatus.offline,
    'syncing' => SyncUiStatus.syncing,
    'issue' => SyncUiStatus.issue,
    'pending' => SyncUiStatus.pending,
    _ => SyncUiStatus.upToDate,
  };
});
