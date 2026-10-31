import 'dart:async';

import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:flutter/material.dart';

/// Chrono (02:30) : temps écoulé depuis que la course a été prise.
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
      padding: const EdgeInsets.fromLTRB(12, 0, 14, 0),
      height: 48,
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(Radii.pill),
        boxShadow: AppShadows.floating,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            AppIcons.timer,
            size: 16,
            color: context.palette.textSecondary,
          ),
          gapW8,
          Text(
            _text,
            style: TextStyle(
              color: context.palette.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
