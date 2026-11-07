// Seeds categories and menu items from menu_seed.json.
// Real reviews are created only through the authenticated Customer flow.
//
// By default this only writes to the Firestore emulator. Set
// FIRESTORE_EMULATOR_HOST (for example 127.0.0.1:8080) before running.
// Writing to a real project requires --allow-production and local
// credentials that must never be committed.
import { readFileSync } from 'node:fs';

import { initializeApp } from 'firebase-admin/app';
import { FieldValue, Timestamp, getFirestore } from 'firebase-admin/firestore';

const allowProduction = process.argv.includes('--allow-production');
if (!process.env.FIRESTORE_EMULATOR_HOST && !allowProduction) {
  console.error(
    'FIRESTORE_EMULATOR_HOST is not set. Refusing to write to a real ' +
      'project without --allow-production.',
  );
  process.exit(1);
}

const projectId =
  process.env.GCLOUD_PROJECT ?? process.env.FIREBASE_PROJECT ?? 'demo-ordering';
initializeApp({ projectId });
const db = getFirestore();

const seed = JSON.parse(
  readFileSync(new URL('./menu_seed.json', import.meta.url), 'utf8'),
);
const categoriesById = new Map(seed.categories.map((c) => [c.id, c]));

const batch = db.batch();
const now = FieldValue.serverTimestamp();

// Remove reviews created by the old demo seed without touching reviews whose
// ids follow the real `<uid>_<orderId>` format. Firestore does not delete
// subcollections when their parent menu item is overwritten.
const legacyReviewPrefixes = [
  'ga-ran-ga-sot-cay-ngot-han-quoc-r',
  'do-uong-tra-sua-tran-chau-duong-den-r',
  'com-com-ga-chien-mam-toi-r',
];
const isLegacySeedReview = (id) =>
  legacyReviewPrefixes.some((prefix) => id.startsWith(prefix));
const legacyReviewPaths = new Set();
const realReviewSummary = new Map();
const reviewSnapshots = await Promise.all([
  db.collectionGroup('reviews').get(),
  db.collection('reviews').get(),
]);
for (const snapshot of reviewSnapshots) {
  for (const document of snapshot.docs) {
    if (isLegacySeedReview(document.id)) {
      legacyReviewPaths.add(document.ref.path);
      continue;
    }

    const menuItemRef = document.ref.parent.parent;
    if (menuItemRef?.parent.id != 'menu_items') continue;
    const rating = document.data().rating;
    if (!Number.isInteger(rating) || rating < 1 || rating > 5) continue;
    const summary = realReviewSummary.get(menuItemRef.id) ?? {
      total: 0,
      count: 0,
    };
    summary.total += rating;
    summary.count += 1;
    realReviewSummary.set(menuItemRef.id, summary);
  }
}
for (const path of legacyReviewPaths) {
  batch.delete(db.doc(path));
}

if (seed.restaurantName) {
  batch.set(
    db.collection('restaurant_configs').doc('main'),
    {
      restaurantName: seed.restaurantName,
      address: seed.restaurantAddress,
      latitude: seed.restaurantLatitude,
      longitude: seed.restaurantLongitude,
      maxDeliveryDistanceKm: seed.maxDeliveryDistanceKm,
      deliveryRules: seed.deliveryRules,
      paymentMethods: ['cod'],
      updatedAt: now,
    },
    { merge: true },
  );
}

for (const { id, ...category } of seed.categories) {
  batch.set(db.collection('categories').doc(id), {
    ...category,
    createdAt: now,
    updatedAt: now,
  });
}

for (const { id, ...item } of seed.items) {
  const category = categoriesById.get(item.categoryId);
  if (!category) {
    throw new Error(`Item ${id} references unknown category ${item.categoryId}`);
  }
  const reviewSummary = realReviewSummary.get(id);
  const ratingAverage = reviewSummary
    ? Math.round((reviewSummary.total / reviewSummary.count) * 10) / 10
    : 0;
  // Denormalized copies required by firestore.rules and the browse queries.
  batch.set(db.collection('menu_items').doc(id), {
    ...item,
    ratingAverage,
    reviewCount: reviewSummary?.count ?? 0,
    isCategoryPublished: category.isPublished,
    categorySortOrder: category.sortOrder,
    createdAt: now,
    updatedAt: now,
  });
}

// Kept for schema compatibility. The production seed contains no reviews;
// authenticated Customer submissions create both private and public copies.
const reviews = seed.reviews ?? [];
reviews.forEach(({ id, menuItemId, createdAt, updatedAt, ...display }, index) => {
  const timestamps = {
    createdAt: Timestamp.fromMillis(createdAt),
    updatedAt: Timestamp.fromMillis(updatedAt),
  };
  batch.set(
    db.collection('menu_items').doc(menuItemId).collection('reviews').doc(id),
    { ...display, ...timestamps },
  );
  batch.set(db.collection('reviews').doc(id), {
    ...display,
    ...timestamps,
    menuItemId,
    customerId: `demo-customer-${(index % 5) + 1}`,
    orderId: `demo-order-${index + 1}`,
    orderItemId: `demo-order-item-${index + 1}`,
  });
});

await batch.commit();
console.log(
  `Seeded ${seed.categories.length} categories, ${seed.items.length} ` +
    `menu items and ${reviews.length} reviews into project ${projectId}; ` +
    `removed ${legacyReviewPaths.size} legacy mock review documents.`,
);
