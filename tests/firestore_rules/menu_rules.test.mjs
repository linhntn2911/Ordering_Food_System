// Firestore rules tests for menu browsing (specs/002-browse-menu,
// contracts/firestore_menu_access.md cases R1-R10; specs/003-menu-search
// contracts/menu_repository_search.md case R11; specs/004-food-details
// contracts/firestore_review_access.md cases R12-R17).
//
// Run with `npm test`, which starts the Firestore emulator through
// `firebase emulators:exec`.
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  doc,
  getDoc,
  getDocs,
  Timestamp,
  limit,
  orderBy,
  query,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';

const PROJECT_ID = 'demo-ordering';
const ADMIN_UID = 'admin-1';
const CUSTOMER_UID = 'customer-1';
const OTHER_CUSTOMER_UID = 'customer-2';

let testEnv;

const item = (overrides) => ({
  categoryId: 'cat-published',
  name: 'Cơm gà',
  basePrice: 45000,
  isPublished: true,
  isAvailable: true,
  isCategoryPublished: true,
  categorySortOrder: 1,
  sortOrder: 1,
  ratingAverage: 0,
  reviewCount: 0,
  ...overrides,
});

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync(
        new URL('../../firestore.rules', import.meta.url),
        'utf8',
      ),
    },
  });
});

after(async () => {
  await testEnv?.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'users', ADMIN_UID), {
      fullName: 'Admin',
      email: 'admin@example.com',
      phone: '0900000000',
      role: 'admin',
      status: 'active',
    });
    await setDoc(doc(db, 'users', CUSTOMER_UID), {
      fullName: 'Customer',
      email: 'customer@example.com',
      phone: '0900000001',
      role: 'customer',
      status: 'active',
    });
    await setDoc(doc(db, 'categories', 'cat-published'), {
      name: 'Cơm',
      sortOrder: 1,
      isPublished: true,
    });
    await setDoc(doc(db, 'categories', 'cat-hidden'), {
      name: 'Ẩn',
      sortOrder: 2,
      isPublished: false,
    });
    await setDoc(doc(db, 'menu_items', 'item-visible'), item({}));
    await setDoc(
      doc(db, 'menu_items', 'item-sold-out'),
      item({ name: 'Phở', isAvailable: false }),
    );
    await setDoc(
      doc(db, 'menu_items', 'item-unpublished'),
      item({ name: 'Bún', isPublished: false }),
    );
    await setDoc(
      doc(db, 'menu_items', 'item-hidden-category'),
      item({
        name: 'Chè',
        categoryId: 'cat-hidden',
        isCategoryPublished: false,
      }),
    );
    await setDoc(doc(db, 'users', OTHER_CUSTOMER_UID), {
      fullName: 'Other',
      email: 'other@example.com',
      phone: '0900000002',
      role: 'customer',
      status: 'active',
    });
    const publicReview = {
      rating: 5,
      comment: 'Ngon',
      imageUrls: [],
      isAnonymous: false,
      isEdited: false,
      createdAt: Timestamp.fromMillis(1_700_000_000_000),
      updatedAt: Timestamp.fromMillis(1_700_000_000_000),
    };
    await setDoc(
      doc(db, 'menu_items', 'item-visible', 'reviews', 'r1'),
      publicReview,
    );
    await setDoc(
      doc(db, 'menu_items', 'item-unpublished', 'reviews', 'r2'),
      publicReview,
    );
    await setDoc(
      doc(db, 'menu_items', 'item-hidden-category', 'reviews', 'r3'),
      publicReview,
    );
    await setDoc(doc(db, 'reviews', 'r1'), {
      ...publicReview,
      customerId: CUSTOMER_UID,
      orderId: 'order-1',
      orderItemId: 'order-item-1',
      menuItemId: 'item-visible',
    });
  });
});

const guestDb = () => testEnv.unauthenticatedContext().firestore();
const customerDb = () => testEnv.authenticatedContext(CUSTOMER_UID).firestore();
const adminDb = () => testEnv.authenticatedContext(ADMIN_UID).firestore();
const otherCustomerDb = () =>
  testEnv.authenticatedContext(OTHER_CUSTOMER_UID).firestore();

const publicReviewsQuery = (db, menuItemId) =>
  query(
    collection(db, 'menu_items', menuItemId, 'reviews'),
    orderBy('createdAt', 'desc'),
    limit(5),
  );

const browsableQuery = (db) =>
  query(
    collection(db, 'menu_items'),
    where('isPublished', '==', true),
    where('isCategoryPublished', '==', true),
  );

describe('menu browsing rules', () => {
  test('R1 guest can list items with both visibility filters', async () => {
    await assertSucceeds(getDocs(browsableQuery(guestDb())));
  });

  test('R2 guest cannot list items without the category filter', async () => {
    const db = guestDb();
    await assertFails(
      getDocs(
        query(collection(db, 'menu_items'), where('isPublished', '==', true)),
      ),
    );
  });

  test('R3 guest cannot get an unpublished item', async () => {
    await assertFails(getDoc(doc(guestDb(), 'menu_items', 'item-unpublished')));
  });

  test('R4 guest cannot get an item of an unpublished category', async () => {
    await assertFails(
      getDoc(doc(guestDb(), 'menu_items', 'item-hidden-category')),
    );
  });

  test('R5 guest can get a published sold-out item', async () => {
    await assertSucceeds(getDoc(doc(guestDb(), 'menu_items', 'item-sold-out')));
  });

  test('R6 guest cannot get an unpublished category', async () => {
    await assertFails(getDoc(doc(guestDb(), 'categories', 'cat-hidden')));
  });

  test('R7 customer cannot update a menu item', async () => {
    await assertFails(
      updateDoc(doc(customerDb(), 'menu_items', 'item-visible'), {
        basePrice: 1,
      }),
    );
  });

  test('R8 customer cannot create a category', async () => {
    await assertFails(
      setDoc(doc(customerDb(), 'categories', 'cat-new'), {
        name: 'Mới',
        sortOrder: 3,
        isPublished: true,
      }),
    );
  });

  test('R9 admin can get an unpublished item', async () => {
    await assertSucceeds(
      getDoc(doc(adminDb(), 'menu_items', 'item-unpublished')),
    );
  });

  test('R10 signed-in customer can list items with both filters', async () => {
    await assertSucceeds(getDocs(browsableQuery(customerDb())));
  });

  test('R11 guest can list the search query in menu order', async () => {
    await assertSucceeds(
      getDocs(
        query(
          browsableQuery(guestDb()),
          orderBy('categorySortOrder'),
          orderBy('categoryId'),
          orderBy('sortOrder'),
          orderBy('name'),
          limit(300),
        ),
      ),
    );
  });
});

describe('review rules', () => {
  test('R12 guest can list public reviews of a published item', async () => {
    await assertSucceeds(getDocs(publicReviewsQuery(guestDb(), 'item-visible')));
  });

  test('R13 guest cannot list public reviews of a hidden item', async () => {
    await assertFails(
      getDocs(publicReviewsQuery(guestDb(), 'item-unpublished')),
    );
    await assertFails(
      getDocs(publicReviewsQuery(guestDb(), 'item-hidden-category')),
    );
  });

  test('R14 customer cannot create a public review', async () => {
    await assertFails(
      setDoc(doc(customerDb(), 'menu_items', 'item-visible', 'reviews', 'rx'), {
        rating: 5,
        comment: '',
        imageUrls: [],
        isAnonymous: false,
        isEdited: false,
      }),
    );
  });

  test('R15 guest cannot get a private review', async () => {
    await assertFails(getDoc(doc(guestDb(), 'reviews', 'r1')));
  });

  test('R16 only the owner customer can get a private review', async () => {
    await assertSucceeds(getDoc(doc(customerDb(), 'reviews', 'r1')));
    await assertFails(getDoc(doc(otherCustomerDb(), 'reviews', 'r1')));
  });

  test('R17 admin can list public reviews of a hidden item', async () => {
    await assertSucceeds(
      getDocs(publicReviewsQuery(adminDb(), 'item-unpublished')),
    );
  });
});
