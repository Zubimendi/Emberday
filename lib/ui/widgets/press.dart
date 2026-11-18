import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Spring-ish press with light haptic. Respects reduce motion.
class Press extends StatefulWidget {
  const Press({
    super.key,
    required this.child,
    this.onPressed,
    this.onLongPress,
    this.scaleTo = 0.98,
    this.haptic = true,
    this.borderRadius,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final double scaleTo;
  final bool haptic;
  final BorderRadius? borderRadius;
  final bool enabled;

  @override
  State<Press> createState() => _PressState();
}

class _PressState extends State<Press> {
  var _down = false;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      enabled: widget.enabled && widget.onPressed != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.enabled && widget.onPressed != null
            ? (_) => setState(() => _down = true)
            : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.enabled
            ? () {
                if (widget.haptic) HapticFeedback.lightImpact();
                widget.onPressed?.call();
              }
            : null,
        onLongPress: widget.enabled
            ? () {
                if (widget.haptic) HapticFeedback.selectionClick();
                widget.onLongPress?.call();
              }
            : null,
        child: AnimatedScale(
          scale: (!reduce && _down) ? widget.scaleTo : 1,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
