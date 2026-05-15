import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Wraps a horizontal [SingleChildScrollView] so that the mouse scroll wheel
/// (which normally fires vertical deltas) also scrolls horizontally on desktop.
class HorizontalScrollWheel extends StatefulWidget {
  const HorizontalScrollWheel({super.key, required this.child});

  final Widget child;

  @override
  State<HorizontalScrollWheel> createState() => _HorizontalScrollWheelState();
}

class _HorizontalScrollWheelState extends State<HorizontalScrollWheel> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    if (!_controller.hasClients) return;
    // Prefer horizontal delta (trackpad two-finger swipe); fall back to
    // vertical delta (mouse wheel) so both input methods work.
    final delta = event.scrollDelta.dx.abs() > event.scrollDelta.dy.abs()
        ? event.scrollDelta.dx
        : event.scrollDelta.dy;
    _controller.jumpTo(
      (_controller.offset + delta).clamp(0.0, _controller.position.maxScrollExtent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: _onPointerSignal,
      child: ScrollConfiguration(
        behavior: _MouseDragScrollBehavior(),
        child: SingleChildScrollView(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Allows mouse-button drag in addition to touch/trackpad for the scroll view.
class _MouseDragScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}
