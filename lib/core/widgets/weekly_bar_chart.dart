import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Histogramme de la semaine : sept barres arrondies sur leur rail, la
/// barre choisie en orange avec une bulle noire qui donne sa valeur.
class WeeklyBarChart extends StatefulWidget {
  const WeeklyBarChart({
    super.key,
    required this.values,
    required this.valueLabel,
    this.initialSelected,
    this.height = 190,
  });

  /// Sept valeurs, du lundi au dimanche.
  final List<double> values;
  final String Function(double value) valueLabel;
  final int? initialSelected;
  final double height;

  static const labels = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

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
                          final factor = maxValue <= 0 || value <= 0
                              ? 0.0
                              : (value / maxValue).clamp(0.14, 1.0);
                          final barHeight = box.maxHeight * factor;
                          final selected = i == _selected;

                          return Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.bottomCenter,
                            children: [
                              Container(
                                width: 30,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F3F7),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: 30,
                                height: barHeight,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.secondary
                                      : AppColors.primary,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              if (selected)
                                Positioned(
                                  bottom: barHeight + 6,
                                  left: -30,
                                  right: -30,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.textPrimaryLight,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: Text(
                                          widget.valueLabel(value),
                                          maxLines: 1,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 6,
                                        height: 6,
                                        margin: const EdgeInsets.only(top: 3),
                                        decoration: const BoxDecoration(
                                          color: AppColors.textPrimaryLight,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
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
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: i == _selected
                            ? AppColors.textPrimaryLight
                            : AppColors.textHintLight,
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
