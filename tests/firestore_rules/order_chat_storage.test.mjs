import { after, before, test } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { deleteObject, getBytes, getMetadata, ref, uploadBytes } from 'firebase/storage';
import { active, admin, chatEnvironment, disabled, disabledCustomer, old, other, owner } from './order_chat_fixtures.mjs';

let env;
before(async () => { env = await chatEnvironment({ storage: true }); });
after(async () => { await env?.cleanup(); });

function photo(uid, { order = active, message = 'photo', file = '0.jpg' } = {}) {
  const context = uid ? env.authenticatedContext(uid) : env.unauthenticatedContext();
  return ref(context.storage(), ['order_chats', order, message, file].join('/'));
}

function upload(target, size = 1024 * 1024, contentType = 'image/jpeg') {
  return uploadBytes(target, new Uint8Array(size), { contentType });
}

test('S1 Owner may upload a photo for an active order', async () => {
  await assertSucceeds(upload(photo(owner)));
  const bytes = await assertSucceeds(getBytes(photo(owner)));
  if (bytes.byteLength !== 1024 * 1024) throw new Error('Expected the uploaded photo bytes');
});

test('S2 5 MB and larger photos are denied', async () => {
  for (const mb of [5, 6]) {
    await assertFails(upload(photo(owner, { message: 'large' }), mb * 1024 * 1024));
  }
});

test('S3 Non-image and invalid indices are denied', async () => {
  await assertFails(upload(photo(owner, { message: 'pdf' }), 100, 'application/pdf'));
  await assertFails(upload(photo(owner, { file: '3.jpg' })));
});

test('S4 Another customer cannot read or create', async () => {
  await assertFails(upload(photo(other, { message: 'foreign' })));
  await assertFails(getBytes(photo(other)));
});

test('S5 Active Admin can read and upload', async () => {
  await assertSucceeds(getMetadata(photo(admin)));
  await assertSucceeds(upload(photo(admin, { message: 'admin' })));
});

test('S6 Photos cannot be overwritten or deleted', async () => {
  for (const uid of [owner, admin]) {
    await assertFails(upload(photo(uid)));
    await assertFails(deleteObject(photo(uid)));
  }
});

test('S7 Historical orders allow participant image reads and creates', async () => {
  await env.withSecurityRulesDisabled(async (context) => {
    await upload(ref(context.storage(), 'order_chats/order-old/photo/0.jpg'), 100);
  });
  for (const uid of [owner, admin]) {
    await assertSucceeds(getMetadata(photo(uid, { order: old })));
    await assertSucceeds(upload(photo(uid, { order: old, message: uid, file: '1.jpg' })));
  }
});

test('S8 Guests and disabled accounts cannot access photos', async () => {
  await assertFails(getMetadata(photo(undefined)));
  await assertFails(getMetadata(photo(disabled)));
  await assertFails(upload(photo(disabled)));
  await assertFails(upload(photo(disabledCustomer, { order: 'disabled-owner' })));
});
