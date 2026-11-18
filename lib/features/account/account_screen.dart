import 'package:emberday/app_providers.dart';
import 'package:emberday/data/api/auth.dart';
import 'package:emberday/data/sync/status.dart';
import 'package:emberday/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn({required bool signUp}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = ref.read(authServiceProvider);
    final settings = ref.read(settingsRepositoryProvider);
    final result = signUp
        ? await auth.signUp(_email.text.trim(), _password.text)
        : await auth.signIn(_email.text.trim(), _password.text);

    await result.when(
      ok: (userId) async {
        final owner = await settings.syncOwnerId();
        if (owner != null && owner != userId) {
          final replace = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              content: const Text(
                'This phone has data from another account. Replace it with this account\'s data, or cancel?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Replace'),
                ),
              ],
            ),
          );
          if (replace != true) {
            await auth.signOut();
            setState(() => _busy = false);
            return;
          }
          // Wipe local habits/check-ins then pull.
          final db = ref.read(databaseProvider);
          await db.delete(db.checkIns).go();
          await db.delete(db.habits).go();
          await db.delete(db.habitStats).go();
          await db.delete(db.outbox).go();
        }
        await settings.set('sync_owner_id', userId);
        await settings.set('has_session', 'true');
        await ref.read(syncEngineProvider).enqueueInitialAndSync();
        if (mounted) context.pop();
      },
      err: (e) {
        setState(() => _error = e.message);
      },
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final settings = ref.watch(settingsMapProvider).value ?? {};
    final signedIn = settings['has_session'] == 'true';
    final syncStatus = ref.watch(syncStatusProvider);

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(title: const Text('Account and sync')),
      body: ListView(
        padding: EdgeInsets.all(t.screenPadding),
        children: [
          Text(
            'Optional. Your habits stay on this phone unless you sign in.',
            style: TextStyle(color: t.textSecondary),
          ),
          SizedBox(height: t.space16),
          if (signedIn) ...[
            Text('Signed in', style: TextStyle(color: t.success)),
            SizedBox(height: t.space8),
            Text('Sync: ${syncStatus.label}'),
            SizedBox(height: t.space8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Sync center'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/sync'),
            ),
            TextButton(
              onPressed: () async {
                await ref.read(authServiceProvider).signOut();
                await ref
                    .read(settingsRepositoryProvider)
                    .set('has_session', 'false');
              },
              child: Text('Sign out', style: TextStyle(color: t.danger)),
            ),
          ] else ...[
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: t.space12),
            TextField(
              controller: _password,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            if (_error != null) ...[
              SizedBox(height: t.space8),
              Text(_error!, style: TextStyle(color: t.danger)),
            ],
            SizedBox(height: t.space16),
            FilledButton(
              onPressed: _busy ? null : () => _signIn(signUp: false),
              style: FilledButton.styleFrom(backgroundColor: t.primary),
              child: const Text('Sign in'),
            ),
            TextButton(
              onPressed: _busy ? null : () => _signIn(signUp: true),
              child: const Text('Create account'),
            ),
          ],
        ],
      ),
    );
  }
}

class SyncCenterScreen extends ConsumerWidget {
  const SyncCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final outbox = ref.watch(outboxRepositoryProvider);

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(title: const Text('Sync center')),
      body: FutureBuilder(
        future: Future.wait([outbox.pending(), outbox.parkedCount()]),
        builder: (context, snap) {
          final pending =
              (snap.data?[0] as List?)?.length ?? 0;
          final parked = snap.data?[1] as int? ?? 0;
          return ListView(
            padding: EdgeInsets.all(t.screenPadding),
            children: [
              ListTile(
                title: const Text('Waiting'),
                trailing: Text('$pending'),
              ),
              ListTile(
                title: const Text('Failed / parked'),
                trailing: Text('$parked'),
              ),
              FilledButton(
                onPressed: () => ref.read(syncEngineProvider).requestSync(),
                child: const Text('Sync now'),
              ),
            ],
          );
        },
      ),
    );
  }
}
