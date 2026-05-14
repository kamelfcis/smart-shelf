import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import '../providers/shelf_detail_provider.dart';

class ItemHistoryScreen extends ConsumerWidget {
  const ItemHistoryScreen({
    super.key,
    required this.itemId,
    this.itemName,
  });

  final String itemId;
  final String? itemName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(itemLogsProvider(itemId));

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              SmartShelfAppBar(
                title: itemName ?? 'Item History',
                subtitle: 'Weight over time',
              ),
              Expanded(
                child: logsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      'Failed to load history',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.error),
                    ),
                  ),
                  data: (logs) {
                    if (logs.isEmpty) {
                      return Center(
                        child: Text(
                          'No history available yet',
                          style: AppTypography.bodyMedium,
                        ),
                      );
                    }

                    // Build chart spots (reverse so oldest first)
                    final reversed = logs.reversed.toList();
                    final spots = <FlSpot>[];
                    for (var i = 0; i < reversed.length; i++) {
                      spots.add(FlSpot(
                        i.toDouble(),
                        reversed[i].weightG,
                      ));
                    }

                    final maxY = spots
                            .map((s) => s.y)
                            .reduce((a, b) => a > b ? a : b) *
                        1.2;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(
                        AppDimensions.screenPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Chart card
                          GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Weight History',
                                  style: AppTypography.headingSmall,
                                ),
                                const SizedBox(height: AppDimensions.lg),
                                SizedBox(
                                  height: 220,
                                  child: LineChart(
                                    LineChartData(
                                      minY: 0,
                                      maxY: maxY,
                                      gridData: FlGridData(
                                        drawHorizontalLine: true,
                                        drawVerticalLine: false,
                                        getDrawingHorizontalLine: (v) =>
                                            FlLine(
                                          color: AppColors.border,
                                          strokeWidth: 1,
                                        ),
                                      ),
                                      borderData: FlBorderData(show: false),
                                      titlesData: FlTitlesData(
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 44,
                                            getTitlesWidget: (v, meta) =>
                                                Text(
                                              AppFormatters.weight(v),
                                              style: AppTypography.caption,
                                            ),
                                          ),
                                        ),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                        topTitles: const AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                        rightTitles: const AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                      ),
                                      lineBarsData: [
                                        LineChartBarData(
                                          spots: spots,
                                          isCurved: true,
                                          curveSmoothness: 0.3,
                                          color: AppColors.primary,
                                          barWidth: 2.5,
                                          isStrokeCapRound: true,
                                          dotData: const FlDotData(show: false),
                                          belowBarData: BarAreaData(
                                            show: true,
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                AppColors.primary.withAlpha(60),
                                                AppColors.primary.withAlpha(0),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 500.ms),

                          const SizedBox(height: AppDimensions.lg),

                          // Recent readings list
                          Text(
                            'Recent Readings',
                            style: AppTypography.headingSmall,
                          ).animate(delay: 200.ms).fadeIn(),

                          const SizedBox(height: AppDimensions.md),

                          ...logs.take(20).toList().asMap().entries.map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppDimensions.sm,
                                  ),
                                  child: GlassCard(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppDimensions.md,
                                      vertical: AppDimensions.sm + 4,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            AppFormatters.fullDate(
                                              entry.value.recordedAt,
                                            ),
                                            style: AppTypography.bodySmall,
                                          ),
                                        ),
                                        Text(
                                          AppFormatters.weight(
                                            entry.value.weightG,
                                          ),
                                          style: AppTypography.monoSmall
                                              .copyWith(
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        if (entry.value.qty != null) ...[
                                          const SizedBox(
                                            width: AppDimensions.md,
                                          ),
                                          Text(
                                            '${entry.value.qty} units',
                                            style: AppTypography.monoSmall,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                )
                                    .animate(
                                      delay: Duration(
                                        milliseconds: 300 + (entry.key * 40),
                                      ),
                                    )
                                    .fadeIn(duration: 300.ms)
                                    .slideX(begin: 0.1),
                              ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
