import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Gros chrono orange (02:30) : temps écoulé depuis que la course a été
/// prise.
class ElapsedTimerPill extends StatefulWidget {
  const ElapsedTimerPill({super.key, required this.since});

  final DateTime? since;

  @override
  State<ElapsedTimerPill> createState() => _ElapsedTimerPillState();
}

class _ElapsedTimerPillState extends State<ElapsedTimerPill> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _text {
    final since = widget.since;
    final elapsed = since == null
        ? Duration.zero
        : DateTime.now().difference(since);
    final safe = elapsed.isNegative ? Duration.zero : elapsed;

    String two(int n) => n.toString().padLeft(2, '0');
    final hours = safe.inHours;
    final minutes = safe.inMinutes.remainder(60);
    final seconds = safe.inSeconds.remainder(60);
    return hours > 0
        ? '$hours:${two(minutes)}:${two(seconds)}'
        : '${two(minutes)}:${two(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Text(
        _text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 30,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
