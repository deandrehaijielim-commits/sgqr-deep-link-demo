import 'package:flutter/material.dart';

/// This app's identity within the SGQR deep-linking methods comparison —
/// named "Bank N" to match the visual/UX pattern of bank_app_a/b/c, even
/// though its purpose is demonstrating Verified Android App Links, not a distinct bank.
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
  id: 'methodApplinks',
  name: 'Bank 1',
  color: Color(0xFF6A4C93),
  methodLabel: 'Verified Android App Links',
  platformBadge: 'Android only',
  platformBadgeBg: Color(0xFFE8F5E9),
  platformBadgeFg: Color(0xFF2E7D32),
);

/// Backend base URL, baked in at build time via --dart-define=BACKEND_URL=...
const String kBackendBaseUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'https://sgqr-deep-link-demo.onrender.com',
);
