import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/sales_report.dart';
import 'admin_order_list_view_model.dart';

enum SalesReportPeriod {
  last7Days('Last 7 days'),
  last30Days('Last 30 days'),
  thisMonth('This month');

  const SalesReportPeriod(this.label);
  final String label;

  ({DateTime start, DateTime end}) range(DateTime now) {
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return switch (this) {
      SalesReportPeriod.last7Days => (
        start: tomorrow.subtract(const Duration(days: 7)),
        end: tomorrow,
      ),
      SalesReportPeriod.last30Days => (
        start: tomorrow.subtract(const Duration(days: 30)),
        end: tomorrow,
      ),
      SalesReportPeriod.thisMonth => (
        start: DateTime(now.year, now.month),
        end: tomorrow,
      ),
    };
  }
}

final salesReportPeriodProvider =
    NotifierProvider<SalesReportPeriodViewModel, SalesReportPeriod>(
      SalesReportPeriodViewModel.new,
    );

class SalesReportPeriodViewModel extends Notifier<SalesReportPeriod> {
  @override
  SalesReportPeriod build() => SalesReportPeriod.last7Days;

  void select(SalesReportPeriod value) => state = value;
}

final salesReportProvider = StreamProvider.autoDispose<SalesReport>((ref) {
  final period = ref.watch(salesReportPeriodProvider);
  final range = period.range(DateTime.now());
  return ref
      .watch(orderRepositoryProvider)
      .watchSalesReport(startInclusive: range.start, endExclusive: range.end);
});
