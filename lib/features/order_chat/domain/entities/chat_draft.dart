class ChatDraft {
  ChatDraft({this.text = '', List<String> imageUrls = const []})
    : imageUrls = List.unmodifiable(imageUrls);

  static const maxPhotos = 3;
  static const maxUrlLength = 2048;
  static const maxTextLength = 1000;

  final String text;
  final List<String> imageUrls;

  static bool isImageUrl(String value) {
    final uri = Uri.tryParse(value);
    return value.length <= maxUrlLength &&
        RegExp(
          r'^https://[A-Za-z0-9][A-Za-z0-9.-]*(?::[0-9]+)?(?:[/?#][^\s]*)?$',
        ).hasMatch(value) &&
        uri != null &&
        uri.host.isNotEmpty;
  }

  bool get canSend =>
      (text.trim().isNotEmpty || imageUrls.isNotEmpty) &&
      text.trim().runes.length <= maxTextLength &&
      imageUrls.length <= maxPhotos &&
      imageUrls.every(isImageUrl);
}
