import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/features/reviews/data/models/review_model.dart';

final _createdAt = DateTime.utc(2026, 10, 18, 9, 30);

Map<String, dynamic> _reviewData([Map<String, dynamic> overrides = const {}]) {
  return {
    'rating': 4,
    'comment': 'Gà giòn, sốt vừa miệng.',
    'imageUrls': ['https://example.com/a.jpg'],
    'isAnonymous': true,
    'isEdited': true,
    'createdAt': Timestamp.fromDate(_createdAt),
    'updatedAt': Timestamp.fromDate(_createdAt),
    ...overrides,
  };
}

void main() {
  group('ReviewModel.fromMap', () {
    test('reads every display field', () {
      final review = ReviewModel.fromMap('r1', _reviewData()).toEntity();

      expect(review.id, 'r1');
      expect(review.rating, 4);
      expect(review.comment, 'Gà giòn, sốt vừa miệng.');
      expect(review.imageUrls, ['https://example.com/a.jpg']);
      expect(review.isAnonymous, isTrue);
      expect(review.isEdited, isTrue);
      expect(review.createdAt.toUtc(), _createdAt);
      expect(review.authorLabel, 'Khách hàng ẩn danh');
    });

    for (final rating in <Object?>[0, 6, 4.5, '5', null]) {
      test('rejects rating $rating', () {
        expect(
          () => ReviewModel.fromMap('r', _reviewData({'rating': rating})),
          throwsFormatException,
        );
      });
    }

    test('requires createdAt as a timestamp', () {
      expect(
        () => ReviewModel.fromMap('r', _reviewData()..remove('createdAt')),
        throwsFormatException,
      );
      expect(
        () => ReviewModel.fromMap('r', _reviewData({'createdAt': 'hôm qua'})),
        throwsFormatException,
      );
    });

    test('falls back to defaults for optional fields', () {
      final data = _reviewData()
        ..remove('comment')
        ..remove('imageUrls')
        ..remove('isAnonymous')
        ..remove('isEdited');

      final review = ReviewModel.fromMap('r', data).toEntity();

      expect(review.comment, isEmpty);
      expect(review.imageUrls, isEmpty);
      expect(review.isAnonymous, isFalse);
      expect(review.isEdited, isFalse);
      expect(review.authorLabel, 'Khách hàng');
    });

    test('keeps at most three non-empty image urls', () {
      final review = ReviewModel.fromMap(
        'r',
        _reviewData({
          'imageUrls': ['a', '', 42, 'b', null, 'c', 'd'],
        }),
      ).toEntity();

      expect(review.imageUrls, ['a', 'b', 'c']);
    });
  });
}
