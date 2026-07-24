import 'dart:async';
import 'dart:convert';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Backend URL is baked in at build time:
//   flutter build ios --dart-define=BACKEND_URL=https://sgqr-deep-link-demo.onrender.com
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
  String _status = 'Waiting for a Smart App Banner tap…';

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
    // app-argument delivers whatever URL was configured in the meta tag —
    // here that's smartbannerdemo://pay?token=... — same query-param shape
    // as the other custom-scheme apps in this project.
    final token = uri.queryParameters['token'] ??
        (uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null);
    if (token == null) return;
    setState(() {
      _lastToken = token;
      _status = 'Link received via app-argument — fetching payload…';
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
          _status = 'Opened via the Smart App Banner\'s app-argument';
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
      title: 'Method Demo: Smart App Banner',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF2A9D8F), useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(title: const Text('iOS Smart App Banner')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This app demonstrates the iOS Smart App Banner: a '
                '<meta name="apple-itunes-app"> tag on a webpage that lets '
                'Safari show a banner suggesting to open (or install) this '
                'app — no Associated Domains entitlement required at all.',
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tapping "OPEN" in the banner (if the app is installed) '
                'passes the meta tag\'s app-argument value to this app, '
                'which this demo reads the same way as an ordinary custom '
                'URL scheme link.',
                style: TextStyle(fontSize: 13, color: Colors.black45, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 8),
              const Text(
                'Important limitation: Safari only renders the banner for '
                'an app-id that matches a REAL, published App Store '
                'listing — it validates against Apple\'s servers, not just '
                'the presence of the tag. This demo app is sideloaded and '
                'not published, so the banner itself cannot actually '
                'appear no matter how correct the meta tag is. See project '
                'docs for the full explanation.',
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
