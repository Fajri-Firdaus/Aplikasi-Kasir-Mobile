import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/presentation/widgets/restart_widget.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const RestartWidget(
      child: ProviderScope(child: MobilePOSApp()),
    ),
  );
}

class MobilePOSApp extends ConsumerWidget {
  const MobilePOSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Mobile POS',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
