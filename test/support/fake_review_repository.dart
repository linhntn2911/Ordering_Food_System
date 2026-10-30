import 'dart:async';

import 'package:ordering_food_system/features/menu/domain/entities/menu_feed.dart';
import 'package:ordering_food_system/features/reviews/domain/entities/review.dart';
import 'package:ordering_food_system/features/reviews/domain/repositories/review_repository.dart';

typedef ReviewRequest = ({String menuItemId, int limit});

/// In-memory [ReviewRepository] driven by explicit `emit*` calls.
///
/// Each item's stream replays its latest feed to new listeners, unless
/// [holdReplays] is set to observe load-more states.
class FakeReviewRepository implements ReviewRepository {
  final requests = <ReviewRequest>[];
  final _channels = <String, _Channel>{};

  bool holdReplays = false;

  @override
  Stream<MenuFeed<Review>> watchMenuItemReviews(
    String menuItemId, {
    required int limit,
  }) {
    requests.add((menuItemId: menuItemId, limit: limit));
    return _channel(menuItemId).stream(replay: !holdReplays);
  }

  void emitReviews(
    String menuItemId,
    List<Review> reviews, {
    bool isFromCache = false,
    bool hasMore = false,
  }) {
    _channel(
      menuItemId,
    ).add(MenuFeed(items: reviews, isFromCache: isFromCache, hasMore: hasMore));
  }

  void emitReviewsError(String menuItemId, Object error) =>
      _channel(menuItemId).addError(error);

  _Channel _channel(String menuItemId) =>
      _channels.putIfAbsent(menuItemId, _Channel.new);
}

class _Channel {
  final _controller = StreamController<MenuFeed<Review>>.broadcast();
  MenuFeed<Review>? _latest;

  Stream<MenuFeed<Review>> stream({bool replay = true}) async* {
    final latest = _latest;
    if (replay && latest != null) {
      yield latest;
    }
    yield* _controller.stream;
  }

  void add(MenuFeed<Review> feed) {
    _latest = feed;
    _controller.add(feed);
  }

  void addError(Object error) {
    _latest = null;
    _controller.addError(error);
  }
}
