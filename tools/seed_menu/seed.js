// Seeds categories, menu items and demo reviews from menu_seed.json.
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

if (seed.restaurantName) {
  batch.set(
    db.collection('restaurant_configs').doc('main'),
    { restaurantName: seed.restaurantName, paymentMethods: ['cod'], updatedAt: now },
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
  // Denormalized copies required by firestore.rules and the browse queries.
  batch.set(db.collection('menu_items').doc(id), {
    ...item,
    isCategoryPublished: category.isPublished,
    categorySortOrder: category.sortOrder,
    createdAt: now,
    updatedAt: now,
  });
}

// Public review copies carry no customer or order identifiers; the private
// review keeps them (specs/004-food-details/contracts/firestore_review_access.md).
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
    `menu items and ${reviews.length} reviews into project ${projectId}.`,
);
