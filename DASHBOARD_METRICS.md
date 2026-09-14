# How the dashboard figures are worked out

This describes the **web system's** overview dashboard (USEA Smart Inventory
Management System, `views/overview/summary.php`), not a screen of this app. It
is kept here because the app shows some of the same numbers.

Four figures are worked out for each catalogue — **Materials**, **Books** and
**Assets** — and then added together. The values move with the data, so none is
quoted here.

---

## 1. តម្លៃសរុប — Total stock value

**Materials and books** — `ProductRepository::stockValue()`:

- Takes every product that is not archived (`activeThresholds()`).
- For each, walks its open FIFO batches (`openBatches()`): the deliveries whose
  units are still on the shelf, oldest used first.
- Adds `units still on the shelf × what was paid per unit` for every batch, and
  rounds to 2 decimals.

So the value is what the remaining stock actually cost, not today's price.

**Assets** — `AssetRepository::summary()` adds each asset model's `value`, which
`AssetRepository::list()` works out as the sum of `assets_items`.`unit_cost`
over that model's units.

## 2. ចំនួនសរុប — Total units in stock

**Materials and books** — `ProductRepository::summary()` adds the stock on hand
of every product that is not archived. Stock on hand comes from
`ProductRepository::stockMap()`, per product:

```
on hand = received (stock_orders / book_stock_orders . qty)
        − issued   (stock_stockcontrol / book_stock_stockcontrol, signed by movement type)
        + adjusted (stock_adjustment / book_stock_adjustment . ad_total)
```

It is summed from the history every time, never stored.

**Assets** — the number of `assets_items` rows (units) across all models.

## 3. ប្រភេទទំនិញ — Distinct items

- **Materials / Books:** the number of products that are not archived.
- **Assets:** the number of asset models (`assets` rows).

## 4. ស្តុកជិតអស់ — Low stock

- **Materials / Books:** a product (not archived) is low when its stock on hand
  is **at or below its threshold** — the product's `low_stock` column, or 5 when
  it has none.
- **Assets:** a model is counted when it has **no units** at all.

---

## Adding them up

1. Each catalogue's `summary()` returns `items`, `units`, `value` and `low`.
2. `views/overview/_gather.php` collects the three and adds them into the grand
   totals (`$grand`), skipping any catalogue the signed-in account cannot open.
3. `views/overview/summary.php` shows the totals and the per-catalogue cards.

| File | Role |
|------|------|
| `src/Repositories/ProductRepository.php` | Materials and books: `summary()`, `stockValue()`, `stockMap()`, `openBatches()` |
| `src/Repositories/AssetRepository.php` | Assets: `list()`, `summary()` |
| `views/overview/_gather.php` | Collects and totals the three catalogues |
| `views/overview/summary.php` | The dashboard screen |
| `api/v1/stock.php` | The same summary over the API |
| `live.php` | The live counts the pages refresh |
