import { after, before, test } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { collection, doc, getDoc, getDocs, query, orderBy, where, runTransaction, serverTimestamp, writeBatch, updateDoc, deleteDoc } from 'firebase/firestore';
import { admin, owner, other, disabled, disabledCustomer, chatEnvironment } from './order_chat_fixtures.mjs';

let env;
before(async () => { env = await chatEnvironment(); });
after(async () => { await env?.cleanup(); });
const db = uid => (uid ? env.authenticatedContext(uid) : env.unauthenticatedContext()).firestore();
const parent = (actor, uid = owner) => doc(actor, 'general_chats', uid);
const msg = (actor, id, uid = owner) => doc(parent(actor, uid), 'messages', id);
function payload(uid, id, { customer = owner, existing = false, text = 'Quán mở mấy giờ?', images = [], senderId = uid, senderRole, identity = {} } = {}) {
  const role = senderRole ?? (uid === admin || uid === disabled ? 'admin' : 'customer');
  const now = serverTimestamp();
  const metadata = { lastMessageId: id, lastMessageAt: now, lastMessagePreview: 'Tin nhắn', lastSenderRole: role, updatedAt: now,
    [role === 'admin' ? 'unreadByCustomer' : 'unreadByAdmin']: true, ...identity };
  return {
    metadata: existing ? metadata : { customerId: customer, customerName: 'Khách hàng', openedByRole: role, unreadByAdmin: false, unreadByCustomer: false, createdAt: now, ...metadata },
    message: { senderId, senderRole: role, text, imagePaths: images, createdAt: now },
  };
}
function send(uid, id, options = {}) {
  const actor = db(uid), data = payload(uid, id, options), batch = writeBatch(actor);
  if (options.existing) batch.update(parent(actor, options.customer), data.metadata);
  else batch.set(parent(actor, options.customer), data.metadata);
  batch.set(msg(actor, id, options.customer), data.message);
  return batch.commit();
}

test('G1 customer starts general chat without any order and Admin replies', async () => {
  await assertSucceeds(send(other, 'first', { customer: other }));
  await assertSucceeds(send(admin, 'reply', { customer: other, existing: true }));
  await assertSucceeds(getDoc(msg(db(other), 'reply', other)));
});
test('G2 owner can start a single UID-keyed history', async () => {
  await assertSucceeds(send(owner, 'first'));
  await assertSucceeds(send(owner, 'next', { existing: true }));
  await assertFails(send(owner, 'wrong-thread', { customer: other }));
});
test('G3 Guests, foreign customers and disabled accounts cannot read or write', async () => {
  for (const uid of [undefined, other, disabled, disabledCustomer]) {
    await assertFails(getDoc(parent(db(uid))));
    await assertFails(getDoc(msg(db(uid), 'first')));
    await assertFails(send(uid, 'denied-' + uid, { existing: true, senderId: uid ?? 'guest' }));
  }
  await assertFails(send(disabledCustomer, 'own-disabled', { customer: disabledCustomer }));
});
test('G4 sender, role and customer identities cannot be forged', async () => {
  await assertFails(send(owner, 'forged-id', { existing: true, senderId: admin }));
  await assertFails(send(owner, 'forged-role', { existing: true, senderRole: 'admin' }));
  await assertFails(send(owner, 'forged-owner', { existing: true, identity: { customerId: other } }));
});
test('G5 empty, oversized and invalid images are rejected; HTTPS photos accepted', async () => {
  for (const [id, text, images] of [['empty', ' ', []], ['long', 'a'.repeat(1001), []], ['bad', '', ['http://example.com/a.jpg']], ['many', '', Array.from({length:4},(_,i)=>`https://example.com/${i}.jpg`)], ['storage', '', ['order_chats/x/y/0.jpg']]]) {
    await assertFails(send(owner, id, { existing: true, text, images }));
  }
  await assertSucceeds(send(owner, 'photo', { existing: true, text: '', images: ['https://example.com/a.jpg'] }));
});
test('G6 metadata cannot advance without a message; messages cannot edit/delete', async () => {
  await assertFails(updateDoc(parent(db(owner)), { lastMessageId: 'orphan', lastMessageAt: serverTimestamp(), updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(msg(db(owner), 'first'), { text: 'edit' }));
  await assertFails(deleteDoc(msg(db(admin), 'first')));
});
test('G7 only viewer unread may clear and order history stays separate', async () => {
  await assertFails(updateDoc(parent(db(owner)), { unreadByAdmin: false }));
  await assertSucceeds(updateDoc(parent(db(admin)), { unreadByAdmin: false }));
  await assertSucceeds(send(admin, 'reply', { existing: true }));
  await assertSucceeds(updateDoc(parent(db(owner)), { unreadByCustomer: false }));
  await env.withSecurityRulesDisabled(async ctx => {
    const snapshot = await getDoc(doc(ctx.firestore(), 'order_chats', owner));
    if (snapshot.exists()) throw Error('General writes leaked into order history');
  });
});
test('G8 Admin lists inbox and Customer may only query their own unread', async () => {
  await assertSucceeds(getDocs(query(collection(db(admin), 'general_chats'), orderBy('lastMessageAt', 'desc'))));
  await assertSucceeds(getDocs(query(collection(db(owner), 'general_chats'), where('customerId', '==', owner), where('unreadByCustomer', '==', true))));
  await assertFails(getDocs(collection(db(owner), 'general_chats')));
});
test('G9 concurrent first sends and retried IDs converge on one conversation', async () => {
  const actor = db(owner);
  await env.withSecurityRulesDisabled(async ctx => { await deleteDoc(parent(ctx.firestore())); });
  async function transactionSend(id) {
    return runTransaction(actor, async tx => {
      const existingMessage = await tx.get(msg(actor, id));
      if (existingMessage.exists()) return;
      const exists = (await tx.get(parent(actor))).exists();
      const data = payload(owner, id, { existing: exists });
      if (exists) tx.update(parent(actor), data.metadata); else tx.set(parent(actor), data.metadata);
      tx.set(msg(actor, id), data.message);
    });
  }
  await assertSucceeds(Promise.all([transactionSend('race-a'), transactionSend('race-b')]));
  await assertSucceeds(transactionSend('race-a'));
  const snapshot = await assertSucceeds(getDoc(parent(actor)));
  if (snapshot.data().customerId !== owner) throw Error('Wrong owner');
});
