import { after, before, test } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import {
  collection, doc, getDoc, getDocs, deleteDoc, orderBy, query, runTransaction,
  serverTimestamp, setDoc, updateDoc, where, writeBatch, Timestamp,
} from 'firebase/firestore';
import {
  active, admin, chatEnvironment, disabled, disabledCustomer, old, other, owner, recent,
} from './order_chat_fixtures.mjs';

let env;
before(async () => { env = await chatEnvironment(); });
after(async () => { await env?.cleanup(); });

const db = (uid) => (uid ? env.authenticatedContext(uid) : env.unauthenticatedContext()).firestore();
const chat = (db, order = active) => doc(db, 'order_chats', order);
const message = (db, order, id = 'first') => doc(chat(db, order), 'messages', id);

function write(uid, {
  order = active, id = 'first', existing = false, parent = {}, child = {},
} = {}) {
  const actor = db(uid);
  const role = uid === admin || uid === disabled ? 'admin' : 'customer';
  const time = serverTimestamp();
  const batch = writeBatch(actor);
  const last = {
    lastMessageId: id, lastMessageAt: time, lastMessagePreview: 'Xin chào',
    lastSenderRole: role, updatedAt: time,
    [role === 'admin' ? 'unreadByCustomer' : 'unreadByAdmin']: true,
    ...parent,
  };
  if (existing) batch.update(chat(actor, order), last);
  else batch.set(chat(actor, order), {
    orderId: order, orderCode: order.toUpperCase(), customerId: owner,
    issueType: 'other', openedByRole: role, unreadByAdmin: false,
    unreadByCustomer: false, createdAt: time, ...last,
  });
  batch.set(message(actor, order, id), {
    senderId: uid, senderRole: role, text: 'Xin chào', imagePaths: [],
    createdAt: time, ...child,
  });
  return batch.commit();
}

test('C1 Customer creates the parent and first message together', async () => {
  await assertSucceeds(write(owner));
  await assertSucceeds(getDoc(message(db(owner), active)));
});

test('C2 A different Customer cannot read or write', async () => {
  await assertFails(getDoc(chat(db(other))));
  await assertFails(getDoc(message(db(other), active)));
  await assertFails(write(other, { existing: true, id: 'foreign' }));
});

test('C3 Guest cannot read or send', async () => {
  await assertFails(getDoc(chat(db())));
  await assertFails(getDoc(message(db(), active)));
  await assertFails(write(undefined, { existing: true, id: 'guest', child: { senderId: 'guest' } }));
});

test('C4 Active Admin can read and list', async () => {
  const actor = db(admin);
  await assertSucceeds(getDoc(chat(actor)));
  await assertSucceeds(getDoc(message(actor, active)));
  await assertSucceeds(getDocs(query(collection(actor, 'order_chats'), orderBy('lastMessageAt'))));
});

test('C5 Disabled accounts cannot access chat, even as the order owner', async () => {
  await assertFails(getDoc(chat(db(disabled))));
  await assertFails(write(disabled, { existing: true, id: 'disabled' }));
  await assertFails(getDoc(chat(db(disabledCustomer), 'disabled-owner')));
  await assertFails(write(disabledCustomer, { order: 'disabled-owner', parent: { customerId: disabledCustomer } }));
});

test('C6 Sender identity and role cannot be forged', async () => {
  for (const child of [{ senderId: admin }, { senderRole: 'admin' }]) {
    await assertFails(write(owner, { existing: true, id: 'forged', child }));
  }
});

test('C7 Message time must be server time', async () => {
  await assertFails(write(owner, {
    existing: true, id: 'bad-time', child: { createdAt: Timestamp.fromMillis(0) },
  }));
});

test('C8 Empty content and over-limit content are rejected', async () => {
  for (const child of [
    { text: '' }, { text: '  \n  ' }, { text: 'a'.repeat(1001) },
    { imagePaths: Array.from({ length: 4 }, (_, index) => 'order_chats/order-active/over/' + index + '.jpg') },
  ]) {
    await assertFails(write(owner, { existing: true, id: 'over', child }));
  }
});

test('C9 Paths are restricted to this message and valid indices', async () => {
  for (const path of ['elsewhere.jpg', 'order_chats/order-active/path/3.jpg']) {
    await assertFails(write(owner, { existing: true, id: 'path', child: { imagePaths: [path] } }));
  }
  await assertSucceeds(write(owner, {
    existing: true, id: 'photo', child: { text: '', imagePaths: ['order_chats/order-active/photo/0.jpg'] },
  }));
});

test('a photo-only HTTPS attachment can be sent, but unsafe or oversized links are denied', async () => {
  const url = 'https://example.com/anh.jpg?size=small';
  await assertSucceeds(write(owner, {
    existing: true, id: 'url-photo', child: { text: '', imagePaths: [url] },
  }));
  for (const link of ['http://example.com/anh.jpg', 'https://', 'https://example.com/a b', 'https://example.com/' + 'a'.repeat(2048)]) {
    await assertFails(write(owner, {
      existing: true, id: 'bad-url', child: { text: '', imagePaths: [link] },
    }));
  }
});

test('C10 Neither side may edit or delete a message', async () => {
  for (const uid of [owner, admin]) {
    await assertFails(updateDoc(message(db(uid), active), { text: 'edited' }));
    await assertFails(deleteDoc(message(db(uid), active)));
  }
});

test('C11 A recent terminal order accepts messages', async () => {
  await assertSucceeds(write(owner, { order: recent }));
  await assertSucceeds(write(admin, { order: 'recent-rejected' }));
});

test('C12 Both sides can start and continue chat on old terminal orders', async () => {
  for (const uid of [owner, admin]) {
    for (const base of [old, 'old-cancelled', 'old-rejected']) {
      const order = uid === admin ? base + '-admin' : base;
      await assertSucceeds(write(uid, { order, id: 'start-' + uid }));
      await assertSucceeds(write(uid, { order, id: 'reply-' + uid, existing: true }));
    }
  }
});

test('C13 Historical chat remains readable, writable and can be marked read', async () => {
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(chat(context.firestore(), old), { customerId: owner, unreadByAdmin: true });
    await setDoc(message(context.firestore(), old), { text: 'History' });
  });
  for (const uid of [owner, admin]) {
    await assertSucceeds(getDoc(chat(db(uid), old)));
    await assertSucceeds(getDoc(message(db(uid), old)));
  }
  await assertSucceeds(updateDoc(chat(db(admin), old), { unreadByAdmin: false }));
  await assertSucceeds(write(admin, { order: old, id: 'late', existing: true }));
});

test('C14 Parent identity fields are immutable', async () => {
  for (const parent of [
    { customerId: other }, { issueType: 'lateDelivery' },
    { openedByRole: 'admin' }, { orderCode: 'EDITED' },
  ]) {
    await assertFails(write(owner, { existing: true, id: 'edit', parent }));
  }
});

test('C15 Customer may clear own unread flag', async () => {
  await assertSucceeds(write(admin, { existing: true, id: 'reply' }));
  await assertSucceeds(updateDoc(chat(db(owner)), { unreadByCustomer: false }));
});

test('C16 Customer may not clear Admin unread flag', async () => {
  await assertFails(updateDoc(chat(db(owner)), { unreadByAdmin: false }));
});

test('C17 Admin may clear only their side', async () => {
  await assertSucceeds(write(admin, { existing: true, id: 'reply2' }));
  await assertSucceeds(updateDoc(chat(db(admin)), { unreadByAdmin: false }));
  await assertFails(updateDoc(chat(db(admin)), { unreadByCustomer: false }));
});

test('C18 Parent must correspond to a real order and match the order owner', async () => {
  await assertFails(write(owner, { order: 'missing' }));
  await assertFails(write(other, { order: recent, parent: { customerId: other } }));
  await assertFails(write(owner, { order: 'recent-rejected', parent: { customerId: other } }));
});

test('C19 Customer can query own unread conversations', async () => {
  const actor = db(owner);
  await assertSucceeds(getDocs(query(collection(actor, 'order_chats'),
    where('customerId', '==', owner), where('unreadByCustomer', '==', true))));
});

test('C20 Customer cannot query all conversations', async () => {
  await assertFails(getDocs(collection(db(owner), 'order_chats')));
});

test('A message and its parent metadata cannot be advanced independently', async () => {
  const actor = db(owner);
  await assertFails(setDoc(message(actor, active, 'standalone'), {
    senderId: owner, senderRole: 'customer', text: 'Unlinked', imagePaths: [],
    createdAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(chat(actor), {
    lastMessageId: 'missing', lastMessageAt: serverTimestamp(), updatedAt: serverTimestamp(),
    lastSenderRole: 'customer', unreadByAdmin: true,
  }));
});

test('Concurrent first sends converge and retrying an ID keeps one message', async () => {
  const order = 'race-order';
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'orders', order), {
      orderCode: 'RACE', customerId: owner, orderStatus: 'Preparing',
    });
  });
  async function send(uid, role, id) {
    const actor = db(uid);
    const conversation = chat(actor, order);
    const entry = message(actor, order, id);
    await runTransaction(actor, async (tx) => {
      if ((await tx.get(entry)).exists()) return;
      const previous = await tx.get(conversation);
      const now = serverTimestamp();
      const advance = {
        lastMessageId: id, lastMessageAt: now, updatedAt: now,
        lastMessagePreview: role, lastSenderRole: role,
        [role === 'admin' ? 'unreadByCustomer' : 'unreadByAdmin']: true,
      };
      if (previous.exists()) tx.update(conversation, advance);
      else tx.set(conversation, {
        orderId: order, orderCode: 'RACE', customerId: owner, issueType: 'other',
        openedByRole: role, createdAt: now, unreadByAdmin: false, unreadByCustomer: false,
        ...advance,
      });
      tx.set(entry, { senderId: uid, senderRole: role, text: role, imagePaths: [], createdAt: now });
    });
  }
  await Promise.all([send(owner, 'customer', 'one'), send(admin, 'admin', 'two')]);
  await send(owner, 'customer', 'one');
  await send(owner, 'customer', 'one');
  const messages = await getDocs(collection(chat(db(owner), order), 'messages'));
  if (messages.size !== 2) throw new Error('Expected exactly two messages');
});
