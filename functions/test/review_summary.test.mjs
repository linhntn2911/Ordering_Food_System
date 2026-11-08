import assert from 'node:assert/strict';
import { test } from 'node:test';

import { summarizeRatings } from '../src/review_summary.js';

test('no reviews keeps the summary at zero', () => {
  assert.deepEqual(summarizeRatings(0, 0), { ratingAverage: 0, reviewCount: 0 });
});

test('average is rounded to one decimal place', () => {
  assert.deepEqual(summarizeRatings(3, 13), { ratingAverage: 4.3, reviewCount: 3 });
});

test('a single review sets the average to its rating', () => {
  assert.deepEqual(summarizeRatings(1, 5), { ratingAverage: 5, reviewCount: 1 });
});
