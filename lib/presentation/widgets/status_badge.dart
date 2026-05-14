import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';

enum StockStatus { healthy, low, empty, unknown }

extension StockStatusX on StockStatus {
  Color get color {
    switch (this) {
      case StockStatus.healthy:
        return AppColors.success;
      case StockStatus.low:
        return AppColors.warning;
      case StockStatus.empty:
        return AppColors.error;
      case StockStatus.unknown:
        return AppColors.textHint;
    }
  }

  String get label {
    switch (this) {
      case StockStatus.healthy:
        return 'In Stock';
      case StockStatus.low:
        return 'Low Stock';
      case StockStatus.empty:
        return 'Empty';
      case StockStatus.unknown:
        return 'Unknown';
    }
  }

  IconData get icon {
    switch (this) {
      case StockStatus.healthy:
        return Icons.check_circle_outline_rounded;
      case StockStatus.low:
        return Icons.warning_amber_rounded;
      case StockStatus.empty:
        return Icons.error_outline_rounded;
      case StockStatus.unknown:
        return Icons.help_outline_rounded;
    }
  }
}

StockStatus stockStatusFromQty(int qty, int minThreshold) {
  if (qty <= 0) return StockStatus.empty;
  if (qty <= minThreshold) return StockStatus.low;
  return StockStatus.healthy;
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.showPulse = true,
  });

  final StockStatus status;
  final bool showPulse;

  @override
  Widget build(BuildContext context) {
    final color = status.color;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pulse dot
        SizedBox(
          width: 10,
          height: 10,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (showPulse && status != StockStatus.unknown)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withAlpha(50),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(2.0, 2.0),
                      duration: 1500.ms,
                    )
                    .fadeOut(duration: 1500.ms),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(
                      color: color.withAlpha(120),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppDimensions.xs + 2),
        Text(
          status.label,
          style: AppTypography.labelSmall.copyWith(color: color),
        ),
      ],
    );
  }
}

/// Animated stock progress bar
class StockBar extends StatelessWidget {
  const StockBar({
    super.key,
    required this.current,
    required this.max,
    required this.minThreshold,
    this.height = 4.0,
    this.animate = true,
  });

  final int current;
  final int max;
  final int minThreshold;
  final double height;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final ratio = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    final status = stockStatusFromQty(current, minThreshold);
    final color = status.color;

    Widget bar = ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      child: Stack(
        children: [
          // Track
          Container(
            height: height,
            color: AppColors.surface,
          ),
          // Fill
          FractionallySizedBox(
            widthFactor: ratio,
            child: Container(
              height: height,
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusFull),
                gradient: LinearGradient(
                  colors: [color.withAlpha(180), color],
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withAlpha(80),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (animate) {
      bar = bar
          .animate()
          .slideX(begin: -1, duration: 800.ms, curve: Curves.easeOut);
    }

    return bar;
  }
}

/// Sensor online/offline indicator dot
class SensorDot extends StatelessWidget {
  const SensorDot({super.key, required this.isOnline});
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final color = isOnline ? AppColors.success : AppColors.error;
    return SizedBox(
      width: 10,
      height: 10,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isOnline)
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withAlpha(50),
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(2.2, 2.2),
                  duration: 2.seconds,
                )
                .fadeOut(duration: 2.seconds),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(150),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
