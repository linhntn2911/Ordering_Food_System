enum OrderStatus {
  pending,
  confirmed,
  preparing,
  outForDelivery,
  completed,
  cancelled,
  rejected;

  String get label => switch (this) {
    OrderStatus.pending => 'Chờ xác nhận',
    OrderStatus.confirmed => 'Đã xác nhận',
    OrderStatus.preparing => 'Đang chuẩn bị',
    OrderStatus.outForDelivery => 'Đang giao hàng',
    OrderStatus.completed => 'Hoàn thành',
    OrderStatus.cancelled => 'Đã hủy',
    OrderStatus.rejected => 'Từ chối',
  };

  String get wireValue => switch (this) {
    OrderStatus.pending => 'Pending',
    OrderStatus.confirmed => 'Confirmed',
    OrderStatus.preparing => 'Preparing',
    OrderStatus.outForDelivery => 'OutForDelivery',
    OrderStatus.completed => 'Completed',
    OrderStatus.cancelled => 'Cancelled',
    OrderStatus.rejected => 'Rejected',
  };

  static OrderStatus parse(Object? value) {
    final normalized = value
        ?.toString()
        .replaceAll(RegExp(r'[_\-\s]'), '')
        .toLowerCase();
    return switch (normalized) {
      'pending' => OrderStatus.pending,
      'confirmed' => OrderStatus.confirmed,
      'preparing' => OrderStatus.preparing,
      'outfordelivery' => OrderStatus.outForDelivery,
      'completed' => OrderStatus.completed,
      'cancelled' || 'canceled' => OrderStatus.cancelled,
      'rejected' => OrderStatus.rejected,
      _ => throw FormatException('Trạng thái đơn hàng không xác định: $value'),
    };
  }

  bool canTransitionTo(OrderStatus target) => switch (this) {
    OrderStatus.pending =>
      target == OrderStatus.confirmed || target == OrderStatus.rejected,
    OrderStatus.confirmed => target == OrderStatus.preparing,
    OrderStatus.preparing => target == OrderStatus.outForDelivery,
    OrderStatus.outForDelivery => target == OrderStatus.completed,
    OrderStatus.completed ||
    OrderStatus.cancelled ||
    OrderStatus.rejected => false,
  };

  OrderStatus? get nextFulfillmentStatus => switch (this) {
    OrderStatus.pending => OrderStatus.confirmed,
    OrderStatus.confirmed => OrderStatus.preparing,
    OrderStatus.preparing => OrderStatus.outForDelivery,
    OrderStatus.outForDelivery => OrderStatus.completed,
    OrderStatus.completed ||
    OrderStatus.cancelled ||
    OrderStatus.rejected => null,
  };
}
