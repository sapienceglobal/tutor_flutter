import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/dashboard_stats_model.dart';
import '../utils/constants.dart';

class PerformanceChart extends StatelessWidget {
  final List<ChartDataPoint> data;
  final bool isTutor;

  const PerformanceChart({
    super.key,
    required this.data,
    this.isTutor = false,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyState(context);
    }

    // Check if all data values are 0 (e.g. fresh tutor or student with no activity yet)
    final bool allZero = data.every((e) =>
        (e.value.isNaN || e.value <= 0) &&
        (e.secondaryValue == null ||
            e.secondaryValue!.isNaN ||
            e.secondaryValue! <= 0));

    if (allZero) {
      return _buildEmptyState(context);
    }

    // Compute max and min values safely to prevent NaN division in fl_chart
    double maxVal = 0.0;
    double minVal = 0.0;

    for (final e in data) {
      final v = e.value;
      if (!v.isNaN && !v.isInfinite) {
        if (v > maxVal) maxVal = v;
        if (v < minVal) minVal = v;
      }
      final sv = e.secondaryValue;
      if (sv != null && !sv.isNaN && !sv.isInfinite) {
        if (sv > maxVal) maxVal = sv;
        if (sv < minVal) minVal = sv;
      }
    }

    // Guaranteed safe bounds: maxY MUST be strictly greater than minY!
    final double safeMinY = minVal < 0 ? minVal * 1.15 : 0.0;
    final double safeMaxY =
        maxVal > safeMinY ? (maxVal * 1.25) : (safeMinY + 10.0);
    final double safeMinX = 0.0;
    final double safeMaxX =
        data.length > 1 ? (data.length - 1).toDouble() : 1.0;

    final primarySpots = data.asMap().entries.map((e) {
      final y = e.value.value;
      return FlSpot(
        e.key.toDouble(),
        (y.isNaN || y.isInfinite) ? 0.0 : y,
      );
    }).toList();

    final secondarySpots = isTutor
        ? data.asMap().entries.map((e) {
            final y = e.value.secondaryValue ?? 0.0;
            return FlSpot(
              e.key.toDouble(),
              (y.isNaN || y.isInfinite) ? 0.0 : y,
            );
          }).toList()
        : null;

    return LineChart(
      LineChartData(
        minY: safeMinY,
        maxY: safeMaxY,
        minX: safeMinX,
        maxX: safeMaxX,
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index < 0 || index >= data.length) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    data[index].label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: primarySpots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
          ),
          if (secondarySpots != null)
            LineChartBarData(
              spots: secondarySpots,
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.green.withValues(alpha: 0.1),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primaryTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.insights_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isTutor
                ? 'No revenue or enrollment trends yet'
                : 'No performance history recorded yet',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.navyInk,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            isTutor
                ? 'Growth curves will appear as students enroll and book sessions'
                : 'Complete lessons and quizzes to see your growth curve',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
