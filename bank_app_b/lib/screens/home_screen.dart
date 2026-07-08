import 'package:flutter/material.dart';
import '../balance.dart';
import '../bank_config.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bank = currentBank;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: bank.color,
        foregroundColor: Colors.white,
        title: Text(bank.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: bank.color,
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
            const SizedBox(height: 24),
            const Text(
              'This is a mock bank app for the SGQR deep-linking simulation. '
              'Scan a demo QR code or tap a bank-picker link to trigger a '
              'payment prompt here — including while this app is already open.',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
