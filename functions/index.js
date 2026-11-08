import { initializeApp } from 'firebase-admin/app';
import { AggregateField, FieldValue, getFirestore } from 'firebase-admin/firestore';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';

import { summarizeRatings } from './src/review_summary.js';

initializeApp();

// Keeps menu_items/{id}.reviewCount and ratingAverage in step with the public
// review copies. Clients cannot write menu items, so this runs with admin rights.
export const syncMenuItemReviewSummary = onDocumentWritten(
  {
    document: 'menu_items/{menuItemId}/reviews/{reviewId}',
    region: 'asia-southeast1',
  },
  async (event) => {
    const { menuItemId } = event.params;
    const db = getFirestore();
    const menuItemRef = db.collection('menu_items').doc(menuItemId);

    const snapshot = await menuItemRef
      .collection('reviews')
      .aggregate({
        count: AggregateField.count(),
        total: AggregateField.sum('rating'),
      })
      .get();
    const { count, total } = snapshot.data();

    await menuItemRef.update({
      ...summarizeRatings(count, total),
      updatedAt: FieldValue.serverTimestamp(),
    });
  },
);
