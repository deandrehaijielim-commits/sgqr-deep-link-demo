import 'package:flutter/material.dart';
import '../balance.dart';
import '../bank_config.dart';
import '../payment_api.dart';
import 'payment_success_screen.dart';

class PaymentConfirmScreen extends StatefulWidget {
  final String token;
  const PaymentConfirmScreen({super.key, required this.token});

  @override
  State<PaymentConfirmScreen> createState() => _PaymentConfirmScreenState();
}

class _PaymentConfirmScreenState extends State<PaymentConfirmScreen> {
  late Future<PaymentPayload> _future;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _future = PaymentApi.fetchPayload(widget.token);
  }

  Future<void> _approve(PaymentPayload payload) async {
    setState(() => _confirming = true);
    try {
      await PaymentApi.confirmPayment(payload.token, kBankId);
      if (!mounted) return;
      BalanceStore.pay(payload.amount.toDouble());
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => PaymentSuccessScreen(payload: payload)),
      );
    } on PaymentAlreadyPaidException {
      if (!mounted) return;
      setState(() => _confirming = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('This payment was already completed elsewhere.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _confirming = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bank = currentBank;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: bank.color,
        foregroundColor: Colors.white,
        title: const Text('Confirm payment'),
      ),
      body: FutureBuilder<PaymentPayload>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('${snapshot.error}',
                    style: const TextStyle(color: Colors.red)),
              ),
            );
          }
          final payload = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Paying', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(payload.merchant,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Text('${payload.currency} ${payload.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 36, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Ref: ${payload.reference}',
                    style: const TextStyle(color: Colors.black54)),
                const Spacer(),
                if (payload.paid)
                  const Text('This payment has already been completed.',
                      style: TextStyle(color: Colors.black54))
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _confirming
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: bank.color,
                              foregroundColor: Colors.white),
                          onPressed: _confirming ? null : () => _approve(payload),
                          child: _confirming
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Approve'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
