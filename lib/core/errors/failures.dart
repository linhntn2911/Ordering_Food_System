/// Base failure class for domain and data operations
abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class AuthFailure extends Failure {
  const AuthFailure([
    super.message = 'Bạn cần đăng nhập để thực hiện chức năng này.',
  ]);
}

class CartFailure extends Failure {
  const CartFailure(super.message);
}

class AddressFailure extends Failure {
  const AddressFailure(super.message);
}

class CheckoutFailure extends Failure {
  const CheckoutFailure(super.message);
}

class OrderFailure extends Failure {
  const OrderFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
