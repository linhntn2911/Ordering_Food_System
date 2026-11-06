enum ChatIssueType {
  missingOrWrongItem('Thiếu hoặc sai món'),
  lateDelivery('Giao trễ'),
  foodQuality('Chất lượng món'),
  addressOrContact('Địa chỉ hoặc liên hệ'),
  codPayment('Thanh toán COD'),
  other('Khác');

  const ChatIssueType(this.label);
  final String label;
}
