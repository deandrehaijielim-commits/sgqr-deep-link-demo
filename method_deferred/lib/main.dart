import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String? _lastToken;
  Map<String, dynamic>? _payload;
  String _status = 'Checking clipboard for a pending link…';

  @override
  void initState() {
    super.initState();
    _checkClipboardOnFirstLaunch();
  }

  // The core of the simulation: real store-based deferred deep linking works
  // because the OS/App Store carries a click identifier through the install
  // itself. A sideloaded demo app has no such channel, so this recreates the
  // effect the way some early real-world SDKs actually did before official
  // deferred-linking APIs existed — the web fallback copies the destination
  // to the clipboard right before the (simulated) "go install the app" step,
  // and the app checks the clipboard once on its very first launch.
  Future<void> _checkClipboardOnFirstLaunch() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    final token = _extractToken(text);
    if (token == null) {
      setState(() => _status = 'No pending link found on the clipboard — nothing to recover.');
      return;
    }
    setState(() {
      _lastToken = token;
      _status = 'Found a pending link on the clipboard — fetching payload…';
    });
    await _fetchPayload(token);
  }

  String? _extractToken(String text) {
    final match = RegExp(r'/methods/deferred/([A-Za-z0-9_-]+)').firstMatch(text);
    if (match != null) return match.group(1);
    // Fall back to treating the whole clipboard as a bare token if it looks
    // like one (avoids false positives on arbitrary copied text).
    if (RegExp(r'^[A-Za-z0-9_-]{8,}$').hasMatch(text.trim())) return text.trim();
    return null;
  }

  Future<void> _fetchPayload(String token) async {
    try {
      final res = await http.get(Uri.parse('$backendUrl/api/payload/$token'));
      if (res.statusCode == 200) {
        setState(() {
          _payload = jsonDecode(res.body) as Map<String, dynamic>;
          _status = 'Recovered via deferred-link simulation (clipboard)';
        });
      } else {
        setState(() => _status = 'Payload not found (status ${res.statusCode})');
      }
    } catch (e) {
      setState(() => _status = 'Fetch failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Method Demo: Deferred Deep Linking',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF9B5DE5), useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(title: const Text('Deferred Deep Linking')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This app demonstrates deferred deep linking: opening '
                'specific content after a fresh install, not just on an '
                'already-installed app.',
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              const Text(
                'Real deferred linking (as used by referral/marketing SDKs) '
                'relies on the App/Play Store carrying a click identifier '
                'through the install itself — something only possible for '
                'a genuinely published, store-installed app. This demo is '
                'sideloaded, so it cannot do that. Instead it simulates the '
                'same end result the way some early SDKs actually worked: '
                'the web fallback copies the destination to the clipboard '
                'right before "installing," and the app checks the '
                'clipboard once on first launch.',
                style: TextStyle(fontSize: 13, color: Colors.black45, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 8),
              const Text(
                'Clipboard access on both platforms may show a system '
                'notification the first time an app reads it — that\'s '
                'expected privacy behavior, not a bug.',
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
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () {
                  setState(() => _status = 'Checking clipboard for a pending link…');
                  _checkClipboardOnFirstLaunch();
                },
                child: const Text('Re-check clipboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
