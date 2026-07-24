import 'package:flutter/material.dart';

/// This app's identity within the SGQR deep-linking methods comparison —
/// named "Bank N" to match the visual/UX pattern of bank_app_a/b/c, even
/// though its purpose is demonstrating Verified iOS Universal Links, not a distinct bank.
class MethodConfig {
  final String id;
  final String name;
  final Color color;
  final String methodLabel;
  final String platformBadge;
  final Color platformBadgeBg;
  final Color platformBadgeFg;

  const MethodConfig({
    required this.id,
    required this.name,
    required this.color,
    required this.methodLabel,
    required this.platformBadge,
    required this.platformBadgeBg,
    required this.platformBadgeFg,
  });
}

const MethodConfig currentMethod = MethodConfig(
  id: 'methodUniversallinks',
  name: 'Bank 2',
  color: Color(0xFF0A7EA4),
  methodLabel: 'Verified iOS Universal Links',
  platformBadge: 'iOS only',
  platformBadgeBg: Color(0xFFE3F2FD),
  platformBadgeFg: Color(0xFF0D47A1),
);

/// Backend base URL, baked in at build time via --dart-define=BACKEND_URL=...
const String kBackendBaseUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'https://sgqr-deep-link-demo.onrender.com',
);
