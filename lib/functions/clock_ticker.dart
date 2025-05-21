import 'dart:async';
import 'package:flutter/foundation.dart';

class ClockTicker {
  ClockTicker._() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _notifier.value = DateTime.now();
    });
  }

  static final ClockTicker _instance = ClockTicker._();
  factory ClockTicker() => _instance;

  late final Timer _timer;
  final ValueNotifier<DateTime> _notifier = ValueNotifier(DateTime.now());

  ValueListenable<DateTime> get listenable => _notifier;

  void dispose() => _timer.cancel();
}
