import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:flutter/material.dart';

/// Histogramme de la semaine : sept barres arrondies, la barre choisie en
/// orange avec une bulle qui donne sa valeur. Touchez une barre pour la
/// choisir.
class WeeklyBarChart extends StatefulWidget {
  const WeeklyBarChart({
    super.key,
    required this.values,
    required this.valueLabel,
    this.initialSelected,
    this.height = 180,
  });

  /// Sept valeurs, du lundi au dimanche.
  final List<double> values;
  final String Function(double value) valueLabel;
  final int? initialSelected;
  final double height;

  static const labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart> {
  late int _selected = (widget.initialSelected ?? DateTime.now().weekday - 1)
      .clamp(0, 6);

  @override
  Widget build(BuildContext context) {
    final maxValue = widget.values.fold<double>(0, (a, b) => a > b ? a : b);

    return SizedBox(
      height: widget.height,
      child: Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _selected = i),
                child: Column(
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final value = i < widget.values.length
                              ? widget.values[i]
                              : 0.0;
                          // Une barre vide garde un petit moignon visible.
                          final factor = maxValue <= 0 || value <= 0
                              ? 0.04
                              : (value / maxValue).clamp(0.12, 1.0);
                          final selected = i == _selected;

                          return TweenAnimationBuilder<double>(
                            tween: Tween<double>(
                              begin: 0,
                              end: box.maxHeight * factor,
                            ),
                            duration: Duration(milliseconds: 600 + i * 80),
                            curve: Curves.easeOutCubic,
                            builder: (context, h, _) => Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.bottomCenter,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  width: 22,
                                  height: h,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.secondary
                                        : context.palette.primarySoft,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                if (selected)
                                  Positioned(
                                    bottom: h + 8,
                                    left: -40,
                                    right: -40,
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: context.palette.textPrimary,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          widget.valueLabel(value),
                                          maxLines: 1,
                                          style: TextStyle(
                                            color: context.palette.surface,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      WeeklyBarChart.labels[i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: i == _selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: i == _selected
                            ? context.palette.textPrimary
                            : context.palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
