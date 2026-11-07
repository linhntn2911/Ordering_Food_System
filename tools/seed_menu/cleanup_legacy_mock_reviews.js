// One-time migration that removes only the review documents created by the
// old demo seed. It does not overwrite categories, menu items, images, prices,
// restaurant configuration, or reviews submitted by real customers.
import { initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';

const allowProduction = process.argv.includes('--allow-production');
if (!process.env.FIRESTORE_EMULATOR_HOST && !allowProduction) {
  console.error(
    'FIRESTORE_EMULATOR_HOST is not set. Refusing to update a real project ' +
      'without --allow-production.',
  );
  process.exit(1);
}

const projectId =
  process.env.GCLOUD_PROJECT ?? process.env.FIREBASE_PROJECT ?? 'demo-ordering';
initializeApp({ projectId });
const db = getFirestore();

const affectedMenuItemIds = new Set([
  'ga-ran-ga-sot-cay-ngot-han-quoc',
  'do-uong-tra-sua-tran-chau-duong-den',
  'com-com-ga-chien-mam-toi',
]);
const isLegacyMock = (id) =>
  [...affectedMenuItemIds].some((menuItemId) =>
    id.startsWith(`${menuItemId}-r`),
  );

const [publicReviews, privateReviews] = await Promise.all([
  db.collectionGroup('reviews').get(),
  db.collection('reviews').get(),
]);
const pathsToDelete = new Set();
const realSummary = new Map();

for (const document of publicReviews.docs) {
  const menuItemRef = document.ref.parent.parent;
  if (menuItemRef?.parent.id !== 'menu_items') continue;
  if (isLegacyMock(document.id)) {
    pathsToDelete.add(document.ref.path);
    continue;
  }
  if (!affectedMenuItemIds.has(menuItemRef.id)) continue;
  const rating = document.data().rating;
  if (!Number.isInteger(rating) || rating < 1 || rating > 5) continue;
  const summary = realSummary.get(menuItemRef.id) ?? { total: 0, count: 0 };
  summary.total += rating;
  summary.count += 1;
  realSummary.set(menuItemRef.id, summary);
}
for (const document of privateReviews.docs) {
  if (isLegacyMock(document.id)) pathsToDelete.add(document.ref.path);
}

const batch = db.batch();
for (const path of pathsToDelete) batch.delete(db.doc(path));
for (const menuItemId of affectedMenuItemIds) {
  const summary = realSummary.get(menuItemId);
  batch.set(
    db.collection('menu_items').doc(menuItemId),
    {
      ratingAverage: summary
        ? Math.round((summary.total / summary.count) * 10) / 10
        : 0,
      reviewCount: summary?.count ?? 0,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}
await batch.commit();

console.log(
  `Removed ${pathsToDelete.size} legacy mock review documents and rebuilt ` +
    `rating summaries for ${affectedMenuItemIds.size} menu items in ${projectId}.`,
);
