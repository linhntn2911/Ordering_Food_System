// Builds menu_seed.json from the Ngô Chicken food and drink menus.
// Usage: node tools/seed_menu/build_seed.cjs tools/seed_menu/menu_seed.json
const fs = require('fs');
const path = require('path');

const slug = (s) =>
  s.normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/đ/g, 'd').replace(/Đ/g, 'D')
    .toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
const k = (n) => n * 1000;
const categories = [];
const items = [];
let catOrder = 0;

const addCategory = (name) => {
  const id = slug(name);
  categories.push({ id, name, sortOrder: ++catOrder, isPublished: true, imageUrl: '' });
  return id;
};
const food = (name, list) => {
  const id = addCategory(name);
  list.forEach(([n, p], i) =>
    items.push({ id: `${id}-${slug(n)}`, categoryId: id, name: n, basePrice: k(p), sortOrder: i + 1, sizes: [] }));
};
let drinksId;
let drinkOrder = 0;
const drink = (_group, list) => {
  drinksId ??= addCategory('Đồ uống');
  const id = drinksId;
  list.forEach(([n, m, l]) =>
    items.push({
      id: `${id}-${slug(n)}`, categoryId: id, name: n, basePrice: k(m), sortOrder: ++drinkOrder,
      sizes: l == null ? [] : [{ id: 'm', name: 'M', priceDelta: 0 }, { id: 'l', name: 'L', priceDelta: k(l - m) }],
    }));
};

food('Gà rán', [['Gà viên truyền thống', 30], ['Gà sốt kem hành', 35], ['Gà sốt phô mai cay', 35], ['Gà sốt cay ngọt Hàn Quốc', 35], ['Gà sốt mù tạt mật ong', 35], ['Gà viên mix vị', 35], ['Cánh gà nướng', 30]]);
food('Cơm', [['Cơm gà chiên mắm tỏi', 40], ['Cơm rang gà chiên mắm tỏi', 50], ['Cơm rang dưa bò', 35], ['Cơm rang gà rán', 50], ['Cơm rang gà sốt cay ngọt', 55], ['Cơm rang trứng - xúc xích', 25]]);
food('Mỳ', [['Mỳ ý bò bằm', 35], ['Mỳ cay rau nấm', 25], ['Mỳ cay xúc xích', 30], ['Mỳ cay bò', 35], ['Mỳ cay hải sản', 45], ['Mỳ cay thập cẩm', 50]]);
food('Đồ ăn vặt', [['Bánh gà', 30], ['Khoai tây tươi chiên', 25], ['Khoai tây tươi chiên lắc phô mai', 30], ['Khoai lang kén', 25], ['Nem chua rán', 30], ['Kimbap', 25], ['Cá viên chiên', 25], ['Xúc xích', 10]]);
food('Combo', [['Set gà viên 4 vị sốt + Kimbap', 140], ['Set to 2 kimbap + Gà viên 4 vị sốt + Khoai tây chiên', 200], ['Mỳ cay xúc xích + Trà tắc', 35], ['Mỳ cay rau nấm + Trà tắc', 30], ['Mỳ ý + Gà rán', 60]]);
// Representative drinks only (max 8 per category); see specs/002-browse-menu/spec.md.
drink('Trà', [['Trà chanh', 10, 15], ['Trà đào', 20, 25], ['Trà sữa trân châu đường đen', 25, 30], ['Trà sữa kem muối', 25, 30]]);
drink('Sữa chua', [['Sữa chua lắc dâu', 25, 30]]);
drink('Latte', [['Matcha Latte', 25, 30]]);
drink('Nước ép + Sinh tố', [['Nước ép cam', 25, 30], ['Sinh tố bơ', 25, 30]]);

// Items left out to keep each category short (see specs/002-browse-menu/spec.md).
const removed = new Set([
  'ga-ran-ga-sot-mu-tat-mat-ong', 'ga-ran-ga-vien-mix-vi',
  'com-com-rang-dua-bo', 'com-com-rang-trung-xuc-xich',
  'my-my-cay-rau-nam', 'my-my-cay-xuc-xich',
  'do-an-vat-khoai-lang-ken', 'do-an-vat-xuc-xich',
  'combo-set-to-2-kimbap-ga-vien-4-vi-sot-khoai-tay-chien', 'combo-my-cay-rau-nam-tra-tac',
  'do-uong-tra-chanh', 'do-uong-tra-sua-kem-muoi',
]);
for (const id of removed) {
  const index = items.findIndex((item) => item.id === id);
  if (index < 0) throw new Error(`Unknown removed id ${id}`);
  items.splice(index, 1);
}

// Demo-only stock so the sold-out state shows on the emulator.
const soldOut = new Set(['do-an-vat-ca-vien-chien', 'do-uong-sinh-to-bo']);

for (const id of soldOut) {
  if (!items.some((item) => item.id === id)) throw new Error(`Unknown demo id ${id}`);
}
// Short demo descriptions by category (specs/004-food-details).
const categoryBlurb = {
  'ga-ran': 'Gà chiên giòn rụm, áo sốt đậm vị, ăn nóng ngon nhất.',
  com: 'Cơm nóng ăn kèm rau dưa, phần vừa đủ cho một người.',
  my: 'Sợi mỳ dai, nước dùng đậm đà, chọn được cấp độ cay khi ghi chú.',
  'do-an-vat': 'Món ăn vặt chiên tươi, hợp dùng kèm trà sữa.',
  combo: 'Combo tiết kiệm cho nhóm bạn, đủ no cho bữa xế.',
  'do-uong': 'Pha tươi trong ngày, chọn size M hoặc L.',
};
const milkTeaToppings = [
  { id: 'tran-chau-den', name: 'Trân châu đen', priceDelta: k(5) },
  { id: 'thach-dua', name: 'Thạch dừa', priceDelta: k(5) },
  { id: 'kem-cheese', name: 'Kem cheese', priceDelta: k(8) },
];
const spicyNoodleToppings = [
  { id: 'them-trung', name: 'Thêm trứng', priceDelta: k(5) },
  { id: 'them-xuc-xich', name: 'Thêm xúc xích', priceDelta: k(7) },
];
const toppingsFor = (item) => {
  if (item.categoryId === 'do-uong' && item.name.startsWith('Trà sữa')) return milkTeaToppings;
  if (item.categoryId === 'my' && item.name.startsWith('Mỳ cay')) return spicyNoodleToppings;
  return [];
};

// Demo public reviews (menu_items/{id}/reviews). Rating summaries are
// computed from them so Food Details and the summary always agree.
const day = 24 * 60 * 60 * 1000;
const baseTime = Date.UTC(2026, 9, 19, 12);
const photo = (seed) => `https://picsum.photos/seed/${seed}/600/600`;
const reviewSeeds = {
  'ga-ran-ga-sot-cay-ngot-han-quoc': [
    [5, 'Sốt cay ngọt rất vừa, gà giòn lâu.', [photo('ga1'), photo('ga2')], false, false],
    [4, 'Ngon nhưng hơi ngọt với mình.', [], true, false],
    [5, 'Đặt lần thứ ba rồi, vẫn ngon như cũ.', [], false, true],
    [5, '', [], false, false],
    [4, 'Phần ăn vừa đủ, giao nhanh.', [photo('ga3')], false, false],
    [5, 'Gà nóng hổi, sốt sánh, rất đáng tiền. Lần sau sẽ thử thêm vị phô mai cay và gọi thêm khoai tây chiên để ăn kèm cho đủ bữa.', [], false, false],
    [3, 'Hôm nay gà hơi nguội khi tới nơi.', [], true, false],
    [5, 'Ngon!', [], false, false],
    [4, 'Ổn, sẽ quay lại.', [], false, false],
    [5, 'Sốt Hàn Quốc chuẩn vị.', [photo('ga4'), photo('ga5'), photo('ga6')], false, false],
    [4, '', [], true, false],
    [5, 'Bạn bè đều khen.', [], false, false],
  ],
  'do-uong-tra-sua-tran-chau-duong-den': [
    [5, 'Trân châu dẻo, đường đen thơm.', [photo('ts1')], false, false],
    [4, 'Hơi ngọt, lần sau sẽ ghi chú ít đường.', [], true, false],
    [5, 'Size L uống đã.', [], false, true],
  ],
  'com-com-ga-chien-mam-toi': [
    [5, 'Mắm tỏi thơm, cơm dẻo.', [], false, false],
    [4, 'Gà hơi nhỏ nhưng ngon.', [photo('com1')], false, false],
    [5, '', [], true, false],
  ],
};
const reviews = [];
for (const [menuItemId, list] of Object.entries(reviewSeeds)) {
  list.forEach(([rating, comment, imageUrls, isAnonymous, isEdited], index) => {
    const createdAt = baseTime - index * day;
    reviews.push({
      id: `${menuItemId}-r${String(index + 1).padStart(2, '0')}`,
      menuItemId, rating, comment, imageUrls, isAnonymous, isEdited,
      createdAt, updatedAt: isEdited ? createdAt + day / 2 : createdAt,
    });
  });
}
const reviewSummary = {};
for (const review of reviews) {
  const summary = (reviewSummary[review.menuItemId] ??= { total: 0, count: 0 });
  summary.total += review.rating;
  summary.count += 1;
}

for (const id of Object.keys(reviewSeeds)) {
  if (!items.some((item) => item.id === id)) throw new Error(`Unknown review item ${id}`);
}
for (const item of items) {
  const summary = reviewSummary[item.id];
  const [ratingAverage, reviewCount] = summary
    ? [Math.round((summary.total / summary.count) * 10) / 10, summary.count]
    : [0, 0];
  Object.assign(item, {
    description: `${item.name}. ${categoryBlurb[item.categoryId] ?? ''}`.trim(),
    imageUrl: '', toppings: toppingsFor(item), isPublished: true,
    isAvailable: !soldOut.has(item.id), ratingAverage, reviewCount,
  });
}

const out = path.resolve(process.argv[2]);
fs.writeFileSync(out, JSON.stringify({ restaurantName: 'Ngô Chicken', categories, items, reviews }, null, 2) + '\n');
console.log(`${categories.length} categories, ${items.length} items, ${reviews.length} reviews -> ${out}`);
