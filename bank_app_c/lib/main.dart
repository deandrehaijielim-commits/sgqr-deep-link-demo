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
  Uri? _lastHandledUri;
  DateTime? _lastHandledAt;

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
    // Note: on cold start, uriLinkStream can also re-emit the same initial
    // link that getInitialLink() already returned above — _handleUri
    // dedupes against the last handled URI to avoid pushing the confirm
    // screen twice.
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
    // Only dedupe if the *same* link arrives again within a couple seconds —
    // that's the getInitialLink()/uriLinkStream double-emit on cold start,
    // not a legitimate later re-tap of the same payment link (e.g. after the
    // user cancelled and re-opened it), which must still go through.
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
    final bank = currentBank;
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: bank.name,
      theme: ThemeData(colorSchemeSeed: bank.color, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}
