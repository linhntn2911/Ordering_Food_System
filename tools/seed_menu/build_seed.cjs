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

// Reviews are intentionally not seeded. Food Details reads the public review
// subcollection from Firestore, and only reviews submitted by real customers
// after a completed order may appear there.
const reviews = [];
for (const item of items) {
  Object.assign(item, {
    description: `${item.name}. ${categoryBlurb[item.categoryId] ?? ''}`.trim(),
    imageUrl: '', toppings: toppingsFor(item), isPublished: true,
    isAvailable: !soldOut.has(item.id), ratingAverage: 0, reviewCount: 0,
  });
}

const out = path.resolve(process.argv[2]);
fs.writeFileSync(out, JSON.stringify({
  restaurantName: 'Ngô Chicken',
  restaurantAddress: '123 Nguyễn Huệ, phường Bến Nghé, Quận 1, TP. Hồ Chí Minh',
  restaurantLatitude: 10.7769,
  restaurantLongitude: 106.7009,
  maxDeliveryDistanceKm: 8,
  deliveryRules: [
    { maxDistanceKm: 3, fee: 15000 },
    { maxDistanceKm: 5, fee: 20000 },
    { maxDistanceKm: 8, fee: 30000 },
  ],
  categories,
  items,
  reviews,
}, null, 2) + '\n');
console.log(`${categories.length} categories, ${items.length} items, ${reviews.length} reviews -> ${out}`);
