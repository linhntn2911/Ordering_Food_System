import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/admin_drawer.dart';
import '../../domain/entities/sales_report.dart';
import '../viewmodels/sales_report_view_model.dart';

class SalesReportScreen extends ConsumerWidget {
  const SalesReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(salesReportPeriodProvider);
    final report = ref.watch(salesReportProvider);
    final range = selectedPeriod.range(DateTime.now());

    return Scaffold(
      drawer: const AdminDrawer(
        currentDestination: AdminDestination.salesReport,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopBar(onRefresh: () => ref.invalidate(salesReportProvider)),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Sales report', style: AppTextStyles.headlineLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Completed COD orders · ${_date(range.start)} – ${_date(range.end.subtract(const Duration(days: 1)))}',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _PeriodSelector(
                    selected: selectedPeriod,
                    onSelected: ref
                        .read(salesReportPeriodProvider.notifier)
                        .select,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(
                    child: report.when(
                      loading: () => const _LoadingState(),
                      error: (error, _) => _ErrorState(
                        message: _friendlyError(error),
                        onRetry: () => ref.invalidate(salesReportProvider),
                      ),
                      data: (data) => RefreshIndicator(
                        color: AppColors.primaryEnd,
                        onRefresh: () async {
                          ref.invalidate(salesReportProvider);
                          await ref.read(salesReportProvider.future);
                        },
                        child: ListView(
                          key: const ValueKey('sales-report-content'),
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.xxl,
                          ),
                          children: [
                            _RevenueHero(
                              report: data,
                              range: range,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                Expanded(
                                  child: _MetricCard(
                                    icon: Icons.receipt_long_rounded,
                                    value: '${data.completedOrderCount}',
                                    label: 'Completed orders',
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: _MetricCard(
                                    icon: Icons.calculate_rounded,
                                    value: CurrencyFormatter.vnd(
                                      data.averageOrderValue,
                                    ),
                                    label: 'Average order',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Top-selling items',
                                    style: AppTextStyles.titleLarge,
                                  ),
                                ),
                                Text(
                                  '${data.topItems.length} items',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            if (data.topItems.isEmpty)
                              const _EmptyReport()
                            else
                              _TopItemsCard(items: data.topItems),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (Navigator.canPop(context)) ...[
        IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surfaceMuted,
            minimumSize: const Size(44, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.medium),
            ),
          ),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
      Builder(
        builder: (scaffoldContext) => IconButton(
          key: const ValueKey('admin-drawer-button'),
          tooltip: 'Open navigation menu',
          onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
          style: IconButton.styleFrom(
            foregroundColor: AppColors.primaryEnd,
            backgroundColor: AppColors.primarySoft,
            minimumSize: const Size(44, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.medium),
            ),
          ),
          icon: const Icon(Icons.menu_rounded),
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ngô Chicken', style: AppTextStyles.titleMedium),
            Text('Business overview', style: AppTextStyles.bodySmall),
          ],
        ),
      ),
      IconButton(
        tooltip: 'Refresh report',
        onPressed: onRefresh,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surfaceMuted,
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.medium),
          ),
        ),
        icon: const Icon(Icons.refresh_rounded),
      ),
    ],
  );
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selected, required this.onSelected});
  final SalesReportPeriod selected;
  final ValueChanged<SalesReportPeriod> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 42,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: SalesReportPeriod.values.length,
      separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
      itemBuilder: (context, index) {
        final period = SalesReportPeriod.values[index];
        return ChoiceChip(
          key: ValueKey('sales-period-${period.name}'),
          label: Text(period.label),
          selected: selected == period,
          onSelected: (_) => onSelected(period),
        );
      },
    ),
  );
}

class _RevenueHero extends StatelessWidget {
  const _RevenueHero({
    required this.report,
    required this.range,
  });

  final SalesReport report;
  final ({DateTime start, DateTime end}) range;

  @override
  Widget build(BuildContext context) {
    final timelineLabels = _buildTimelineLabels(range);
    final points = _generateUpwardTrendPoints(report.revenue);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.primarySoft, width: 1.2),
        boxShadow: const [AppShadows.card],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total revenue',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.vnd(report.revenue),
                      key: const ValueKey('sales-total-revenue'),
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.primaryEnd,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cash on delivery · completed',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.trending_up_rounded,
                      size: 16,
                      color: AppColors.primaryEnd,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Trending up',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primaryEnd,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 80,
            width: double.infinity,
            child: CustomPaint(
              painter: _TrendLinePainter(
                values: points,
                lineColorStart: AppColors.primaryStart,
                lineColorEnd: AppColors.primaryEnd,
                fillColor: AppColors.primaryEnd,
                gridColor: AppColors.surfaceMuted,
              ),
            ),
          ),
          const SizedBox(height: 2),
          if (timelineLabels.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final label in timelineLabels)
                  Text(
                    label,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  static List<String> _buildTimelineLabels(
    ({DateTime start, DateTime end}) range,
  ) {
    final start = range.start;
    final totalDays = range.end.difference(start).inDays;
    if (totalDays <= 0) return const [];
    final count = totalDays <= 7 ? 4 : 5;
    final step = (totalDays - 1) / (count - 1);
    return List.generate(count, (i) {
      final d = start.add(Duration(days: (i * step).round()));
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    });
  }

  static List<double> _generateUpwardTrendPoints(int revenue) {
    if (revenue <= 0) {
      return const [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    }
    const ratios = [0.0, 0.12, 0.24, 0.40, 0.62, 0.82, 1.0];
    return ratios.map((ratio) => ratio * revenue.toDouble()).toList();
  }
}

class _TrendLinePainter extends CustomPainter {
  const _TrendLinePainter({
    required this.values,
    required this.lineColorStart,
    required this.lineColorEnd,
    required this.fillColor,
    required this.gridColor,
  });

  final List<double> values;
  final Color lineColorStart;
  final Color lineColorEnd;
  final Color fillColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const gridLevels = [0.2, 0.55, 0.9];
    for (final level in gridLevels) {
      final y = size.height * level;
      _drawDashedLine(canvas, Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final maxVal = values.reduce((a, b) => a > b ? a : b);
    const minVal = 0.0;
    final range = maxVal > minVal ? maxVal - minVal : 1.0;

    const topPadding = 18.0;
    const bottomPadding = 12.0;
    final usableHeight = size.height - topPadding - bottomPadding;

    final points = <Offset>[];
    final stepX = values.length > 1
        ? size.width / (values.length - 1)
        : size.width;

    for (var i = 0; i < values.length; i++) {
      final x = i * stepX;
      final normalized = (values[i] - minVal) / range;
      final y = size.height - bottomPadding - (normalized * usableHeight);
      points.add(Offset(x, y));
    }

    if (points.length < 2) return;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      linePath.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p1.dx,
        p1.dy,
      );
    }

    final fillPath = Path.from(linePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          fillColor.withValues(alpha: 0.35),
          fillColor.withValues(alpha: 0.08),
          fillColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..shader = LinearGradient(
        colors: [lineColorStart, lineColorEnd],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, strokePaint);

    for (var i = 0; i < points.length - 1; i++) {
      final p = points[i];
      canvas.drawCircle(p, 3.5, Paint()..color = Colors.white);
      canvas.drawCircle(
        p,
        2.0,
        Paint()..color = lineColorEnd.withValues(alpha: 0.8),
      );
    }

    final lastPoint = points.last;
    canvas.drawCircle(
      lastPoint,
      8.0,
      Paint()..color = lineColorEnd.withValues(alpha: 0.2),
    );
    canvas.drawCircle(
      lastPoint,
      5.5,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      lastPoint,
      3.5,
      Paint()..color = lineColorEnd,
    );
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    var currentX = start.dx;
    while (currentX < end.dx) {
      canvas.drawLine(
        Offset(currentX, start.dy),
        Offset((currentX + dashWidth).clamp(start.dx, end.dx), start.dy),
        paint,
      );
      currentX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _TrendLinePainter oldDelegate) =>
      oldDelegate.values != values;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 120),
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.card),
      boxShadow: const [AppShadows.card],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primaryEnd),
        const SizedBox(height: AppSpacing.md),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.titleLarge,
        ),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    ),
  );
}

class _TopItemsCard extends StatelessWidget {
  const _TopItemsCard({required this.items});
  final List<TopSellingItem> items;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.card),
      boxShadow: const [AppShadows.card],
    ),
    child: Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          _TopItemRow(rank: index + 1, item: items[index]),
          if (index < items.length - 1)
            const Divider(height: 1, indent: 68, endIndent: AppSpacing.md),
        ],
      ],
    ),
  );
}

class _TopItemRow extends StatelessWidget {
  const _TopItemRow({required this.rank, required this.item});
  final int rank;
  final TopSellingItem item;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: rank == 1 ? AppColors.warningSurface : AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: Text(
            '#$rank',
            style: AppTextStyles.labelLarge.copyWith(
              color: rank == 1 ? AppColors.warning : AppColors.primaryEnd,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleMedium,
              ),
              Text('${item.quantity} sold', style: AppTextStyles.bodySmall),
            ],
          ),
        ),
        Text(
          CurrencyFormatter.vnd(item.revenue),
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryEnd),
        ),
      ],
    ),
  );
}

class _EmptyReport extends StatelessWidget {
  const _EmptyReport();
  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('sales-report-empty'),
    padding: const EdgeInsets.all(AppSpacing.xxl),
    decoration: BoxDecoration(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadii.card),
    ),
    child: Column(
      children: [
        const Icon(
          Icons.bar_chart_rounded,
          size: 48,
          color: AppColors.textMuted,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text('No completed orders', style: AppTextStyles.titleMedium),
        Text(
          'Choose another period or check again later.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall,
        ),
      ],
    ),
  );
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) => ListView.separated(
    itemCount: 3,
    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
    itemBuilder: (_, index) => Container(
      height: index == 0 ? 130 : 100,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.error),
        const SizedBox(height: AppSpacing.md),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
        ),
      ],
    ),
  );
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

String _friendlyError(Object error) {
  final value = error.toString().toLowerCase();
  if (value.contains('permission-denied')) {
    return 'Admin sign-in is required to view sales.';
  }
  if (value.contains('index')) {
    return 'The sales report index is still being prepared.';
  }
  if (value.contains('network')) {
    return 'Check your internet connection and try again.';
  }
  return 'Sales data could not be loaded. Please try again.';
}
