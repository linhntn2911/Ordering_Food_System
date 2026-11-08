/// Rating summary for a menu item from the number of reviews and the sum of
/// their star ratings. Empty menu items keep both fields at zero.
export function summarizeRatings(reviewCount, ratingTotal) {
  if (!Number.isInteger(reviewCount) || reviewCount <= 0) {
    return { ratingAverage: 0, reviewCount: 0 };
  }
  const average = Math.round((ratingTotal / reviewCount) * 10) / 10;
  return { ratingAverage: average, reviewCount };
}
