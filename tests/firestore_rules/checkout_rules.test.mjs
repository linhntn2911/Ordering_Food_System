import { readFileSync } from 'node:fs';
import { after, before, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, serverTimestamp, writeBatch } from 'firebase/firestore';

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-ordering',
    firestore: {
      rules: readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8'),
    },
  });
});

after(async () => {
  await testEnv?.cleanup();
});

function submitOrder(context, orderId, customerId) {
  const db = context.firestore();
  const batch = writeBatch(db);
  batch.set(doc(db, 'orders', orderId), {
    orderCode: 'ORD-20261106-1234',
    customerId,
    customerName: 'Customer',
    customerPhone: '0901234567',
    deliveryAddress: 'Delivery address',
    addressSnapshot: { fullAddress: 'Delivery address' },
    totalAmount: 55000,
    subtotal: 40000,
    deliveryFee: 15000,
    deliveryDistanceKm: 2.2,
    paymentMethod: 'cod',
    paymentStatus: 'unpaid',
    orderStatus: 'Pending',
    customerNote: '',
    cancellationReason: '',
    rejectionReason: '',
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
  batch.set(doc(db, 'orders', orderId, 'items', 'item_0'), {
    menuItemId: 'chicken-rice',
    name: 'Chicken rice',
    imageUrl: '',
    basePrice: 40000,
    selectedSize: 'Standard',
    selectedToppings: [],
    quantity: 1,
    unitPrice: 40000,
    lineTotal: 40000,
    note: '',
    reviewed: false,
  });
  return batch.commit();
}

test('a customer can create their own COD order and item in one batch', async () => {
  const customer = testEnv.authenticatedContext('checkout-customer');
  await assertSucceeds(submitOrder(customer, 'checkout-owned', 'checkout-customer'));
});

test('checkout rejects signed-out users and mismatched customer IDs', async () => {
  const customer = testEnv.authenticatedContext('checkout-customer');
  await assertFails(submitOrder(customer, 'checkout-other', 'other-customer'));
  await assertFails(
    submitOrder(testEnv.unauthenticatedContext(), 'checkout-guest', 'checkout-customer'),
  );
});
