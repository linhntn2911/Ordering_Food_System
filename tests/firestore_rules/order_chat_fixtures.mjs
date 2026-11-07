import { readFileSync } from 'node:fs';
import { initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, setDoc, Timestamp } from 'firebase/firestore';

export const owner = 'customer-1';
export const other = 'customer-2';
export const admin = 'admin-1';
export const disabled = 'admin-off';
export const disabledCustomer = 'customer-off';
export const active = 'order-active';
export const recent = 'order-recent';
export const old = 'order-old';

const rules = (file) => readFileSync(new URL('../../' + file, import.meta.url), 'utf8');

export async function chatEnvironment({ storage = false } = {}) {
  const env = await initializeTestEnvironment({
    projectId: 'demo-ordering',
    firestore: { rules: rules('firestore.rules') },
    ...(storage ? { storage: { rules: rules('storage.rules') } } : {}),
  });
  await env.clearFirestore();
  if (storage) await env.clearStorage();
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const now = Date.now();
    const users = [
      [owner, 'customer', 'active'],
      [other, 'customer', 'active'],
      [admin, 'admin', 'active'],
      [disabled, 'admin', 'disabled'],
      [disabledCustomer, 'customer', 'disabled'],
    ];
    for (const [uid, role, status] of users) {
      await setDoc(doc(db, 'users', uid), { role, status });
    }
    for (const [id, orderStatus, hours, customerId] of [
      [active, 'Preparing', 0, owner],
      [recent, 'Completed', 2, owner],
      [old, 'Completed', 25, owner],
      ['old-cancelled', 'Cancelled', 25, owner],
      ['recent-rejected', 'Rejected', 2, owner],
      ['disabled-owner', 'Preparing', 0, disabledCustomer],
    ]) {
      const ended = Timestamp.fromMillis(now - hours * 3600000);
      await setDoc(doc(db, 'orders', id), {
        orderCode: id.toUpperCase(), customerId, orderStatus,
        completedAt: orderStatus === 'Completed' ? ended : null,
        updatedAt: ended,
      });
    }
  });
  return env;
}
