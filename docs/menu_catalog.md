# Ngô Chicken Menu Catalogue

## Restaurant Profile

Ngô Chicken is a single-restaurant food-ordering application for fried chicken,
rice, noodles, snacks, combos, and drinks. Prices are stored as integer VND;
the `k` notation printed on the source menu is display shorthand only.

## Categories

1. Gà rán
2. Cơm
3. Mì
4. Đồ ăn vặt
5. Combo
6. Trà
7. Sữa chua
8. Sữa tươi
9. Latte
10. Nước ngọt
11. Nước ép & Sinh tố

`Combo đặt lớp` is represented as menu items inside the Combo category to keep
the category hierarchy flat for the first release.

## Menu Data Rules

- Each printed dish or drink becomes one `menu_items` document.
- Food prices such as `35k` are stored as `35000`.
- Drink sizes M and L are options on one MenuItem, not separate categories or
  duplicate MenuItems.
- The M price is the base price; the L option stores the additional price.
- A combo is one MenuItem with a description listing all included products.
- Similar fried-chicken parts remain separate MenuItems when customers can
  choose them independently.
- Availability and publication remain separate fields so an item can be sold
  out temporarily without being removed from the menu.
