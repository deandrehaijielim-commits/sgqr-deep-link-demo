import 'dart:convert';
import 'package:http/http.dart' as http;
import 'bank_config.dart';

class PaymentPayload {
  final String token;
  final String merchant;
  final num amount;
  final String currency;
  final String reference;

  PaymentPayload({
    required this.token,
    required this.merchant,
    required this.amount,
    required this.currency,
    required this.reference,
  });

  factory PaymentPayload.fromJson(Map<String, dynamic> json) => PaymentPayload(
        token: json['token'] as String,
        merchant: json['merchant'] as String,
        amount: json['amount'] as num,
        currency: json['currency'] as String,
        reference: json['reference'] as String,
      );
}

class PaymentApi {
  static Future<PaymentPayload> fetchPayload(String token) async {
    final uri = Uri.parse('$kBackendBaseUrl/api/payload/$token');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Payment not found or expired');
    }
    return PaymentPayload.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
