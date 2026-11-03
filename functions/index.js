const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

initializeApp();
const db = getFirestore();

const REGION = "asia-southeast1";
const REVIEW_WINDOW_MS = 30 * 24 * 60 * 60 * 1000;
const MAX_COMMENT_LENGTH = 500;
const MAX_IMAGES = 3;

function readInput(data) {
  const orderId = typeof data.orderId === "string" ? data.orderId.trim() : "";
  const rating = Number.isInteger(data.rating) ? data.rating : NaN;
  const comment = typeof data.comment === "string" ? data.comment.trim() : "";
  const imageUrls = Array.isArray(data.imageUrls)
    ? data.imageUrls.filter((url) => typeof url === "string")
    : [];

  if (!orderId) {
    throw new HttpsError("invalid-argument", "Thiếu mã đơn hàng.");
  }
  if (!(rating >= 1 && rating <= 5)) {
    throw new HttpsError("invalid-argument", "Số sao phải từ 1 đến 5.");
  }
  if (comment.length > MAX_COMMENT_LENGTH) {
    throw new HttpsError("invalid-argument", "Nhận xét tối đa 500 ký tự.");
  }
  if (rating <= 2 && comment.length === 0) {
    throw new HttpsError(
      "invalid-argument",
      "Vui lòng nhập nhận xét khi đánh giá từ 1 đến 2 sao."
    );
  }
  if (imageUrls.length > MAX_IMAGES) {
    throw new HttpsError("invalid-argument", "Tối đa 3 ảnh cho mỗi đánh giá.");
  }
  return { orderId, rating, comment, imageUrls };
}

function completedAtMillis(order) {
  const updatedAt = order.updatedAt && order.updatedAt.toMillis
    ? order.updatedAt.toMillis()
    : null;
  const createdAt = order.createdAt && order.createdAt.toMillis
    ? order.createdAt.toMillis()
    : null;
  return updatedAt ?? createdAt ?? Date.now();
}

exports.submitReview = onCall({ region: REGION }, async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Cần đăng nhập để đánh giá.");
  }

  const { orderId, rating, comment, imageUrls } = readInput(request.data || {});
  const reviewId = `${uid}_${orderId}`;
  const orderRef = db.collection("orders").doc(orderId);
  const reviewRef = db.collection("reviews").doc(reviewId);

  return db.runTransaction(async (tx) => {
    const orderSnap = await tx.get(orderRef);
    if (!orderSnap.exists) {
      throw new HttpsError("not-found", "Không tìm thấy đơn hàng.");
    }
    const order = orderSnap.data();
    if (order.customerId !== uid) {
      throw new HttpsError("permission-denied", "Đơn hàng không thuộc về bạn.");
    }
    if (String(order.orderStatus || "").toLowerCase() !== "completed") {
      throw new HttpsError(
        "failed-precondition",
        "Chỉ đánh giá được đơn hàng đã hoàn thành."
      );
    }
    if (Date.now() - completedAtMillis(order) > REVIEW_WINDOW_MS) {
      throw new HttpsError(
        "failed-precondition",
        "Đã quá 30 ngày để đánh giá đơn hàng này."
      );
    }

    const existing = await tx.get(reviewRef);
    if (existing.exists) {
      throw new HttpsError("already-exists", "Đơn hàng này đã được đánh giá.");
    }

    const itemsSnap = await tx.get(orderRef.collection("items"));
    const menuItemIds = [
      ...new Set(
        itemsSnap.docs.map((item) => item.get("menuItemId")).filter(Boolean)
      ),
    ];
    const menuSnaps = [];
    for (const menuItemId of menuItemIds) {
      menuSnaps.push(await tx.get(db.collection("menu_items").doc(menuItemId)));
    }

    tx.set(reviewRef, {
      customerId: uid,
      orderId,
      menuItemIds,
      rating,
      comment,
      imageUrls,
      isAnonymous: false,
      isEdited: false,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    for (const menuSnap of menuSnaps) {
      const menuRef = menuSnap.ref;
      tx.set(menuRef.collection("reviews").doc(reviewId), {
        rating,
        comment,
        imageUrls,
        isAnonymous: false,
        isEdited: false,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
      if (menuSnap.exists) {
        const menu = menuSnap.data();
        const count = Number(menu.reviewCount || 0);
        const average = Number(menu.ratingAverage || 0);
        tx.update(menuRef, {
          ratingAverage: (average * count + rating) / (count + 1),
          reviewCount: count + 1,
          updatedAt: FieldValue.serverTimestamp(),
        });
      }
    }

    for (const item of itemsSnap.docs) {
      tx.update(item.ref, { reviewed: true });
    }

    return { reviewId };
  });
});
