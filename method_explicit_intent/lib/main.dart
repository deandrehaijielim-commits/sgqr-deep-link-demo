import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'method_config.dart';
import 'screens/home_screen.dart';
import 'screens/payment_confirm_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MethodApp());
}

class MethodApp extends StatefulWidget {
  const MethodApp({super.key});

  @override
  State<MethodApp> createState() => _MethodAppState();
}

class _MethodAppState extends State<MethodApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;
  Uri? _lastHandledUri;
  DateTime? _lastHandledAt;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) _handleUri(initialUri);
    _linkSub = _appLinks.uriLinkStream.listen(_handleUri);
  }

  String? _extractToken(Uri uri) {
    final fromQuery = uri.queryParameters['token'];
    if (fromQuery != null) return fromQuery;
    if (uri.pathSegments.isNotEmpty) return uri.pathSegments.last;
    return null;
  }

  void _handleUri(Uri uri) {
    final now = DateTime.now();
    final isDuplicate = _lastHandledUri == uri &&
        _lastHandledAt != null &&
        now.difference(_lastHandledAt!) < const Duration(seconds: 2);
    if (isDuplicate) return;
    _lastHandledUri = uri;
    _lastHandledAt = now;
    final token = _extractToken(uri);
    if (token == null) return;
    _navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => PaymentConfirmScreen(token: token)),
    );
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final method = currentMethod;
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: method.name,
      theme: ThemeData(colorSchemeSeed: method.color, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}
