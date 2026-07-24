import 'dart:async';
import 'dart:convert';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Backend URL is baked in at build time:
//   flutter build apk --dart-define=BACKEND_URL=https://sgqr-deep-link-demo.onrender.com
const backendUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'https://sgqr-deep-link-demo.onrender.com',
);

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
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;
  String? _lastToken;
  Map<String, dynamic>? _payload;
  String _status = 'Waiting for a link…';

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

  void _handleUri(Uri uri) {
    final token = uri.queryParameters['token'] ??
        (uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null);
    if (token == null) return;
    setState(() {
      _lastToken = token;
      _status = 'Link received — fetching payload…';
      _payload = null;
    });
    _fetchPayload(token);
  }

  Future<void> _fetchPayload(String token) async {
    try {
      final res = await http.get(Uri.parse('$backendUrl/api/payload/$token'));
      if (res.statusCode == 200) {
        setState(() {
          _payload = jsonDecode(res.body) as Map<String, dynamic>;
          _status = 'Opened via an explicit-package intent — no chooser shown';
        });
      } else {
        setState(() => _status = 'Payload not found (status ${res.statusCode})');
      }
    } catch (e) {
      setState(() => _status = 'Fetch failed: $e');
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Method Demo: Explicit Package Intent',
      theme: ThemeData(colorSchemeSeed: const Color(0xFFE07A5F), useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(title: const Text('Explicit Package Intent')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This app demonstrates the "I already know which app" case: '
                'an intent:// link that names this app\'s package directly '
                'via package=com.sgqrdemo.method_explicit_intent.',
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              const Text(
                'Unlike Verified App Links, this needs no domain ownership '
                'proof and no autoVerify at all — the sender (the QR/link '
                'itself) simply removes the ambiguity by stating exactly '
                'which app should handle it, so Android has nothing left '
                'to disambiguate and skips the chooser unconditionally, '
                'even with every bank app installed.',
                style: TextStyle(fontSize: 13, color: Colors.black45, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 8),
              const Text(
                'Trade-off: this only works because the merchant\'s QR was '
                'generated already knowing the customer\'s bank — the '
                'opposite of this project\'s core scenario, where the '
                'merchant deliberately does NOT know that in advance.',
                style: TextStyle(fontSize: 12, color: Colors.deepOrange),
              ),
              const SizedBox(height: 24),
              Text(_status, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              if (_lastToken != null) ...[
                const SizedBox(height: 12),
                Text('token: $_lastToken', style: const TextStyle(fontFamily: 'monospace')),
              ],
              if (_payload != null) ...[
                const SizedBox(height: 12),
                Text('merchant: ${_payload!['merchant']}'),
                Text('amount: ${_payload!['currency']} ${_payload!['amount']}'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
