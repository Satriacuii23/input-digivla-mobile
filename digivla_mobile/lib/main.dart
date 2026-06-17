import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'core/auth/auth_provider.dart';
import 'router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DigivlaApp());
}

class DigivlaApp extends StatefulWidget {
  const DigivlaApp({super.key});

  @override
  State<DigivlaApp> createState() => _DigivlaAppState();
}

class _DigivlaAppState extends State<DigivlaApp> {
  late final AuthProvider _auth;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _auth = AuthProvider();
    _router = createAppRouter(_auth);
    _auth.bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _auth,
      child: MaterialApp.router(
        title: 'Digivla IDS',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        routerConfig: _router,
      ),
    );
  }
}
