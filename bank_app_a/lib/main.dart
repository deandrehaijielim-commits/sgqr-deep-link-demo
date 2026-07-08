import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'bank_config.dart';
import 'screens/home_screen.dart';
import 'screens/payment_confirm_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BankApp());
}

class BankApp extends StatefulWidget {
  const BankApp({super.key});

  @override
  State<BankApp> createState() => _BankAppState();
}

class _BankAppState extends State<BankApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    // Cold start: app was launched directly from the link.
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) _handleUri(initialUri);

    // Warm start / already running: link arrives while the app is alive.
    _linkSub = _appLinks.uriLinkStream.listen(_handleUri);
  }

  String? _extractToken(Uri uri) {
    final fromQuery = uri.queryParameters['token'];
    if (fromQuery != null) return fromQuery;
    if (uri.pathSegments.isNotEmpty) return uri.pathSegments.last;
    return null;
  }

  void _handleUri(Uri uri) {
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
    final bank = currentBank;
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: bank.name,
      theme: ThemeData(colorSchemeSeed: bank.color, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}
