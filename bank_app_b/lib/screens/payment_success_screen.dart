import 'package:flutter/material.dart';
import '../bank_config.dart';
import '../payment_api.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final PaymentPayload payload;
  const PaymentSuccessScreen({super.key, required this.payload});

  @override
  Widget build(BuildContext context) {
    final bank = currentBank;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: bank.color,
        foregroundColor: Colors.white,
        title: const Text('Payment sent'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: bank.color, size: 72),
            const SizedBox(height: 16),
            Text('${payload.currency} ${payload.amount.toStringAsFixed(2)}',
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('to ${payload.merchant}'),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
