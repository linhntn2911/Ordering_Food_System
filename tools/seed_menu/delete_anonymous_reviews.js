// Deletes only reviews flagged `isAnonymous: true`: the public copies under
// menu_items/{id}/reviews and the private reviews/{id} documents with the same id.
// Dry run by default; pass --apply to delete. Rating summaries of the affected
// menu items are rebuilt from the remaining public reviews.
import { initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';

const apply = process.argv.includes('--apply');
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

const [anonymousPublic, publicReviews] = await Promise.all([
  db.collectionGroup('reviews').where('isAnonymous', '==', true).get(),
  db.collectionGroup('reviews').get(),
]);

const anonymousPublicDocs = anonymousPublic.docs.filter(
  (doc) => doc.ref.parent.parent?.parent.id === 'menu_items',
);
const anonymousIds = new Set(anonymousPublicDocs.map((doc) => doc.id));
const affectedMenuItemIds = new Set(
  anonymousPublicDocs.map((doc) => doc.ref.parent.parent.id),
);

const privateDocs = await Promise.all(
  [...anonymousIds].map((id) => db.collection('reviews').doc(id).get()),
);
const anonymousPrivateRefs = privateDocs
  .filter((doc) => doc.exists && doc.data().isAnonymous === true)
  .map((doc) => doc.ref);

const summary = new Map();
for (const doc of publicReviews.docs) {
  const menuItemRef = doc.ref.parent.parent;
  if (menuItemRef?.parent.id !== 'menu_items') continue;
  if (!affectedMenuItemIds.has(menuItemRef.id)) continue;
  if (anonymousIds.has(doc.id) && doc.data().isAnonymous === true) continue;
  const rating = doc.data().rating;
  if (!Number.isInteger(rating) || rating < 1 || rating > 5) continue;
  const entry = summary.get(menuItemRef.id) ?? { total: 0, count: 0 };
  entry.total += rating;
  entry.count += 1;
  summary.set(menuItemRef.id, entry);
}

console.log(
  `Project ${projectId}: ${anonymousPublicDocs.length} anonymous public reviews, ` +
    `${anonymousPrivateRefs.length} matching private reviews, ` +
    `${affectedMenuItemIds.size} menu items affected.`,
);
for (const doc of anonymousPublicDocs) console.log(`  - ${doc.ref.path}`);

if (!apply) {
  console.log('Dry run only. Re-run with --apply to delete.');
  process.exit(0);
}

const operations = [
  ...anonymousPublicDocs.map((doc) => (batch) => batch.delete(doc.ref)),
  ...anonymousPrivateRefs.map((ref) => (batch) => batch.delete(ref)),
  ...[...affectedMenuItemIds].map((menuItemId) => (batch) => {
    const entry = summary.get(menuItemId);
    batch.set(
      db.collection('menu_items').doc(menuItemId),
      {
        ratingAverage: entry
          ? Math.round((entry.total / entry.count) * 10) / 10
          : 0,
        reviewCount: entry?.count ?? 0,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }),
];

for (let start = 0; start < operations.length; start += 400) {
  const batch = db.batch();
  for (const operation of operations.slice(start, start + 400)) operation(batch);
  await batch.commit();
}

console.log('Deleted anonymous reviews and rebuilt rating summaries.');
