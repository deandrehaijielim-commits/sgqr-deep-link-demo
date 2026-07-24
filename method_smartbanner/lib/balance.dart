import 'package:flutter/foundation.dart';

/// In-memory mock account balance for this app, shared across screens.
/// Resets to the starting balance whenever the app is relaunched.
class BalanceStore {
  BalanceStore._();
  static final ValueNotifier<double> balance = ValueNotifier<double>(1284.50);

  static void pay(double amount) {
    balance.value -= amount;
  }
}
