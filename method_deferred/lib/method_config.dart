import 'package:flutter/material.dart';

/// This app's identity within the SGQR deep-linking methods comparison —
/// named "Bank N" to match the visual/UX pattern of bank_app_a/b/c, even
/// though its purpose is demonstrating Deferred Deep Linking (clipboard simulation), not a distinct bank.
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
  id: 'methodDeferred',
  name: 'Bank 5',
  color: Color(0xFF2D6A4F),
  methodLabel: 'Deferred Deep Linking (clipboard simulation)',
  platformBadge: 'Android + iOS',
  platformBadgeBg: Color(0xFFF3E5F5),
  platformBadgeFg: Color(0xFF6A1B9A),
);

/// Backend base URL, baked in at build time via --dart-define=BACKEND_URL=...
const String kBackendBaseUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'https://sgqr-deep-link-demo.onrender.com',
);
