import 'dart:async';
import 'package:flutter/foundation.dart';

/// Helper class to debounce function calls
class Debounce {
  Timer? _timer;
  final Duration duration;

  Debounce({required this.duration});

  void call(Function() callback) {
    _timer?.cancel();
    _timer = Timer(duration, callback);
  }

  void cancel() {
    _timer?.cancel();
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// Generic debounce extension
extension DebounceExtension<T> on ValueNotifier<T> {
  void debounce(
    Function(T) callback, {
    required Duration delay,
  }) {
    Timer? timer;
    addListener(() {
      timer?.cancel();
      timer = Timer(delay, () => callback(value));
    });
  }
}
