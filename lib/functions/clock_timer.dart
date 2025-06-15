import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CountdownTimer extends StatefulWidget {

  final String datetimeStr;
  final String statusStr;
  const CountdownTimer({
    required this.datetimeStr,
    required this.statusStr,
    Key? key,
  }) : super(key: key);

  @override
  _CountdownTimerState createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  Duration _timeRemaining = Duration.zero;
  late DateTime _matchDateTime;

  @override
  void initState() {
    super.initState();
    _matchDateTime = _parseMatchDateTime(widget.datetimeStr);
    _startCountdown();
  }

  @override
  void didUpdateWidget(covariant CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.datetimeStr != widget.datetimeStr ||
        oldWidget.statusStr != widget.statusStr) {
      _timer?.cancel();
      _matchDateTime = _parseMatchDateTime(widget.datetimeStr);
      _startCountdown();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  DateTime _parseMatchDateTime(String datetimeStr) {
    try {
      final format = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'", 'en_US');
      return format.parseUtc(datetimeStr).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return "00:00:00";
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final h = twoDigits(d.inHours);
    final m = twoDigits(d.inMinutes.remainder(60));
    final s = twoDigits(d.inSeconds.remainder(60));
    return "$h:$m:$s";
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      final remaining = _matchDateTime.difference(now);
      if (remaining.isNegative) {
        _timer?.cancel();
      }
      setState(() {
        _timeRemaining = remaining;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final statusLower = widget.statusStr.toLowerCase();


    Widget content;
    Color bgColor;
    IconData iconData;

    if (_matchDateTime.isAfter(now)) {
      content = Text(
        "تبدأ المباراة خلال: ${_formatDuration(_timeRemaining)}",
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSecondaryContainer,
          fontFamily: 'Cairo',
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
      bgColor = Theme.of(context).colorScheme.secondaryContainer;
      iconData = Icons.schedule;
    } else if (statusLower.contains("إنتهت") || statusLower.contains("انتهت")) {
      content = const Text(
        "انتهت المباراة",
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
      bgColor = Theme.of(context).colorScheme.tertiaryContainer;
      iconData = Icons.check_circle_outline;
    } else {
      content = const Text(
        "المباراة جارية",
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
      bgColor = Theme.of(context).colorScheme.secondaryContainer;
      iconData = Icons.play_arrow;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(iconData, color: Theme.of(context).colorScheme.onSecondaryContainer),
          const SizedBox(width: 8),
          Flexible(child: content),
        ],
      ),
    );
  }
}
