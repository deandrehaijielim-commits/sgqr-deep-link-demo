import 'dart:convert';
import 'package:http/http.dart' as http;
import 'bank_config.dart';

class PaymentPayload {
  final String token;
  final String merchant;
  final num amount;
  final String currency;
  final String reference;
  final bool paid;

  PaymentPayload({
    required this.token,
    required this.merchant,
    required this.amount,
    required this.currency,
    required this.reference,
    required this.paid,
  });

  factory PaymentPayload.fromJson(Map<String, dynamic> json) => PaymentPayload(
        token: json['token'] as String,
        merchant: json['merchant'] as String,
        amount: json['amount'] as num,
        currency: json['currency'] as String,
        reference: json['reference'] as String,
        paid: json['paid'] as bool? ?? false,
      );
}

/// Thrown when another bank app already paid this token first.
class PaymentAlreadyPaidException implements Exception {}

class PaymentApi {
  static Future<PaymentPayload> fetchPayload(String token) async {
    final uri = Uri.parse('$kBackendBaseUrl/api/payload/$token');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Payment not found or expired');
    }
    return PaymentPayload.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<PaymentPayload> confirmPayment(String token, String bankId) async {
    final uri = Uri.parse('$kBackendBaseUrl/api/payload/$token/pay');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'bank': bankId}),
    );
    if (res.statusCode == 409) throw PaymentAlreadyPaidException();
    if (res.statusCode != 200) {
      throw Exception('Failed to confirm payment');
    }
    return PaymentPayload.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
