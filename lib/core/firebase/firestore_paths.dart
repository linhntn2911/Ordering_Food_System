abstract final class FirestorePaths {
  static const users = 'users';
  static const categories = 'categories';
  static const menuItems = 'menu_items';
  static const orders = 'orders';
  static const reviews = 'reviews';
  static const restaurantConfigs = 'restaurant_configs';

  static String user(String userId) => '$users/$userId';
  static String addresses(String userId) => '${user(userId)}/addresses';
  static String favorites(String userId) => '${user(userId)}/favorites';
  static String cartItems(String userId) => '${user(userId)}/cart_items';
  static String notifications(String userId) => '${user(userId)}/notifications';
  static String devices(String userId) => '${user(userId)}/devices';
  static String orderItems(String orderId) => '$orders/$orderId/items';
  static String orderStatusEvents(String orderId) =>
      '$orders/$orderId/status_events';
}
