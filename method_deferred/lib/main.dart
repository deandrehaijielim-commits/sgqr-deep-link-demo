import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String _status = 'Checking clipboard for a pending link…';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkClipboard());
  }

  // The core of the simulation: real store-based deferred deep linking works
  // because the OS/App Store carries a click identifier through the install
  // itself. A sideloaded demo app has no such channel, so this recreates the
  // effect the way some early real-world SDKs actually did before official
  // deferred-linking APIs existed — the web fallback copies the destination
  // to the clipboard right before the (simulated) "go install the app" step,
  // and the app checks the clipboard once on its very first launch.
  Future<void> _checkClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    final token = _extractToken(text);
    if (token == null) {
      setState(() => _status = 'No pending link found on the clipboard — nothing to recover.');
      return;
    }
    setState(() => _status = 'Found a pending link — opening confirm screen…');
    _navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => PaymentConfirmScreen(token: token)),
    );
  }

  String? _extractToken(String text) {
    final match = RegExp(r'/methods/deferred/([A-Za-z0-9_-]+)').firstMatch(text);
    if (match != null) return match.group(1);
    if (RegExp(r'^[A-Za-z0-9_-]{8,}$').hasMatch(text.trim())) return text.trim();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final method = currentMethod;
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: method.name,
      theme: ThemeData(colorSchemeSeed: method.color, useMaterial3: true),
      home: HomeScreen(
        statusText: _status,
        onAction: _checkClipboard,
        actionLabel: 'Re-check clipboard',
      ),
    );
  }
}
