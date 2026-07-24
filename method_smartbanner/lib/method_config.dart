import 'package:flutter/material.dart';

/// This app's identity within the SGQR deep-linking methods comparison —
/// named "Bank N" to match the visual/UX pattern of bank_app_a/b/c, even
/// though its purpose is demonstrating iOS Smart App Banner, not a distinct bank.
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
  id: 'methodSmartbanner',
  name: 'Bank 3',
  color: Color(0xFF2A9D8F),
  methodLabel: 'iOS Smart App Banner',
  platformBadge: 'iOS only',
  platformBadgeBg: Color(0xFFE3F2FD),
  platformBadgeFg: Color(0xFF0D47A1),
);

/// Backend base URL, baked in at build time via --dart-define=BACKEND_URL=...
const String kBackendBaseUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'https://sgqr-deep-link-demo.onrender.com',
);
