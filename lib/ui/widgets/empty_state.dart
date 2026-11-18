import 'package:emberday/ui/tokens.dart';
import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.local_fire_department_outlined,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(t.spaceXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: t.primary),
            SizedBox(height: t.spaceLg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.bodyLarge?.copyWith(color: t.textSecondary),
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: t.spaceXl),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.message = 'Could not load this screen. Check your connection and try again.',
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      message: message,
      actionLabel: onRetry == null ? null : 'Try again',
      onAction: onRetry,
      icon: Icons.error_outline,
    );
  }
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ListView(
      padding: EdgeInsets.all(t.screenPadding),
      children: List.generate(5, (i) {
        return Padding(
          padding: EdgeInsets.only(bottom: t.spaceLg),
          child: _PulseBar(height: i == 0 ? 48 : 64),
        );
      }),
    );
  }
}

class _PulseBar extends StatefulWidget {
  const _PulseBar({required this.height});
  final double height;

  @override
  State<_PulseBar> createState() => _PulseBarState();
}

class _PulseBarState extends State<_PulseBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return FadeTransition(
      opacity: reduce
          ? const AlwaysStoppedAnimation(0.6)
          : Tween(begin: 0.45, end: 1.0).animate(_c),
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: t.surfaceMuted,
          borderRadius: BorderRadius.circular(t.radiusSm),
        ),
      ),
    );
  }
}
