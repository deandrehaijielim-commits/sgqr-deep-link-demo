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
    final token = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
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
          _status = 'Opened via a VERIFIED iOS Universal Link — no prompt shown';
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
      title: 'Method Demo: Verified Universal Links',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF0A7EA4), useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(title: const Text('Verified iOS Universal Links')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This app demonstrates iOS Universal Links: an Associated '
                'Domains entitlement plus a hosted apple-app-site-association '
                '(AASA) file.',
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              const Text(
                'Because the domain is proven to belong to this app alone, '
                'tapping a https://…/methods/universallinks/:token link opens '
                'this app DIRECTLY — no Safari, no confirmation prompt, no '
                'picker of any kind. Unlike a custom scheme, this cannot be '
                'silently hijacked by another app registering the same '
                'address.',
                style: TextStyle(fontSize: 13, color: Colors.black45, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 8),
              const Text(
                'Note: Associated Domains requires a paid Apple Developer '
                'Program membership. This build uses a placeholder Team ID, '
                'so real verification will not succeed until a real one is '
                'swapped in — see project docs.',
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
