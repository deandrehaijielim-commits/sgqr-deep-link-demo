import 'package:flutter/material.dart';

/// One entry per bank flavor. Keys and schemes must match backend/banks.js
/// and each flavor's AndroidManifest.xml / Info.plist URL scheme.
class BankConfig {
  final String id;
  final String name;
  final String scheme;
  final Color color;

  const BankConfig({
    required this.id,
    required this.name,
    required this.scheme,
    required this.color,
  });
}

const Map<String, BankConfig> kBankConfigs = {
  'bankA': BankConfig(
    id: 'bankA',
    name: 'Bank A',
    scheme: 'bankademo',
    color: Color(0xFFE63946),
  ),
  'bankB': BankConfig(
    id: 'bankB',
    name: 'Bank B',
    scheme: 'bankbdemo',
    color: Color(0xFF1D3557),
  ),
  'bankC': BankConfig(
    id: 'bankC',
    name: 'Bank C',
    scheme: 'bankcdemo',
    color: Color(0xFF2A9D8F),
  ),
};

/// This app is a standalone build for Bank C (see bank_app_a / bank_app_b for
/// the other two). Still overridable via --dart-define=BANK=... for testing.
const String kBankId = String.fromEnvironment('BANK', defaultValue: 'bankC');

BankConfig get currentBank => kBankConfigs[kBankId]!;

/// Backend base URL, e.g. an ngrok tunnel or deployed host. Override with
/// --dart-define=BACKEND_URL=http://10.0.2.2:3000 for an Android emulator.
const String kBackendBaseUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'http://localhost:3000',
);
