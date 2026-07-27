import 'package:flutter/material.dart';

/// A widget that wraps the application root and provides a mechanism
/// to completely tear down and rebuild the entire widget tree (app restart).
///
/// This is used during multi-tenant logout and account switching to clear
/// all cached widget states, controllers, and navigation branches.
class RestartWidget extends StatefulWidget {
  final Widget child;

  const RestartWidget({super.key, required this.child});

  /// Triggers a full app restart by recreating the root widget subtree.
  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_RestartWidgetState>()?.restartApp();
  }

  @override
  State<RestartWidget> createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key _key = UniqueKey();

  void restartApp() {
    setState(() {
      _key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _key,
      child: widget.child,
    );
  }
}
