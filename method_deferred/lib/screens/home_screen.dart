import 'package:flutter/material.dart';
import '../balance.dart';
import '../method_config.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.statusText, this.onAction, this.actionLabel});
  final String? statusText;
  final VoidCallback? onAction;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final method = currentMethod;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: method.color,
        foregroundColor: Colors.white,
        title: Text(method.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: method.platformBadgeBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                method.platformBadge,
                style: TextStyle(
                  color: method.platformBadgeFg,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: method.color,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Available balance',
                        style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<double>(
                      valueListenable: BalanceStore.balance,
                      builder: (context, balance, _) => Text(
                        'SGD ${balance.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(method.methodLabel,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            Text(
              "Real deferred linking relies on the App/Play Store carrying a click identifier through installation — not possible for a sideloaded app. This simulates it via the clipboard: the web fallback copies the destination before \"install,\" and this app checks the clipboard once on first launch.",
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Text(
              "Clipboard access may show a system privacy notification the first time an app reads it — that's expected OS behavior, not a bug.",
              style: const TextStyle(color: Colors.deepOrange, fontSize: 12, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 12),
            Text(
              "Tested live on both a real Android device and a real iPhone: correct token recovered both times.",
              style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 12, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (statusText != null) ...[
              Text(statusText!,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
            if (onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onAction,
                child: Text(actionLabel ?? 'Retry'),
              ),
            ],
            
          ],
        ),
      ),
    );
  }
}
