enum ChatFailure implements Exception {
  permissionDenied('Bạn không có quyền xem cuộc trò chuyện này'),
  unavailable('Không gửi được. Kiểm tra kết nối và thử lại'),
  unknown('Đã có lỗi, vui lòng thử lại');

  const ChatFailure(this.message);
  final String message;
}
