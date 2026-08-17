# Dashboard Metrics Calculation Documentation

## Overview

The inventory dashboard displays four key metrics that are aggregated across three inventory types: **Material**, **Book**, and **Asset**.

---

## 1. តម្លៃសរុប (Total Stock Value)

**Displayed value:** $23,414.30

### How it's calculated

For each inventory type, the value is computed differently:

**Materials & Books:**
The value is calculated by iterating through every product and summing the value of its open batches:

```
value += batch.qty_remaining * batch.unit_cost
```

This is implemented in `ProductRepository::stockValue()` (lines 240-251), which:
1. Retrieves all products via `$this->list()`
2. For each product, fetches open batches with `$this->openBatches($id, $stockQty)`
3. Multiplies remaining quantity by unit cost for each batch
4. Returns the total rounded to 2 decimal places

**Assets:**
The value is the sum of the `value` column for all asset models in the `assets_items` table (lines 100-119 of `AssetRepository::summary()`).

### Database tables & columns used

- **Materials/Books:** `stock_orders` / `book_stock_orders` — `pro_id`, `qty` (as `balance`), `price` (as `unit_cost`)
- **Assets:** `assets_items` — `asset_id`, `unit_price` (as `unit_cost`)

---

## 2. ចំនួនសរុប (Total Units in Stock)

**Displayed value:** 28,195

### How it's calculated

For each inventory type, the total units are computed as follows:

**Materials & Books:**
The stock quantity for each product is derived in `ProductRepository::baseQuery()` (lines 793-885) and `stockMap()` (lines 348-379):

```
stock_qty = COALESCE(received.qty, 0) - COALESCE(issued.qty, 0) + COALESCE(adjusted.qty, 0)
```

Where:
- **Received** — sum of `qty` from `stock_orders` / `book_stock_orders` grouped by `pro_id`
- **Issued** — sum of signed quantities from `stock_stockcontrol` / `book_stock_stockcontrol` grouped by `pro_id`
- **Adjusted** — sum of `ad_total` from `stock_adjustment` / `book_stock_adjustment` grouped by `pro_id`

The total units is then the sum of `stock_qty` across all products (line 227 in `ProductRepository::summary()`).

**Assets:**
The total units is the sum of `COALESCE(u.units, 0)` where `u.units` is the count of asset items per model from the `assets_items` table (lines 46-55 of `AssetRepository::list()`).

### Database tables & columns used

- **Materials/Books:**
  - `stock_products` / `book_stock_products` — product list
  - `stock_orders` / `book_stock_orders` — received quantities (`qty` as `balance`)
  - `stock_stockcontrol` / `book_stock_stockcontrol` — issued quantities (`total` as `qty`, `txn_type`)
  - `stock_adjustment` / `book_stock_adjustment` — adjusted quantities (`ad_total` as `qty`)
- **Assets:**
  - `assets_items` — `asset_id` (counted for units)

---

## 3. ប្រភេទទំនិញ (Distinct Items / Product Categories)

**Displayed value:** 788

### How it's calculated

This is simply the count of all product rows (or asset models) across all inventory types:

```
items = count($rows)
```

For **Materials & Books**, `$rows` comes from `$repository->list()` which returns all rows from the product table.

For **Assets**, `$rows` comes from `$this->list()` which returns all rows from the `assets` table (each row represents one type/category of asset).

The grand total is the sum across all three inventory types (Material + Book + Asset).

### Database tables & columns used

- **Materials:** `stock_products` — all rows
- **Books:** `book_stock_products` — all rows
- **Assets:** `assets` — all rows

---

## 4. ស្តុកជិតអស់ (Low Stock Items)

**Displayed value:** 461

### How it's calculated

For each inventory type, "low stock" is determined differently:

**Materials & Books:**
A product is considered "low stock" when its `stock_qty` is less than or equal to its `low_stock_threshold`:

```php
if ($row['stock_qty'] <= $row['low_stock_threshold']) {
    $low++;
}
```

The threshold is configurable per product (default is typically 5 units).

**Assets:**
For assets, "low stock" means zero units remaining:

```php
'low' => count(array_filter($rows, static fn(array $r): bool => (int)$r['stock_qty'] === 0))
```

### Database tables & columns used

- **Materials/Books:** `stock_products` / `book_stock_products` — `low_stock` (mapped to `low_stock_threshold`), plus derived `stock_qty`
- **Assets:** `assets_items` — `asset_id` (counted to determine if any units exist)

---

## Aggregation Process

All four metrics are calculated per inventory type (Material, Book, Asset) and then summed to produce the grand totals displayed on the dashboard:

1. Each system's `summary()` method returns: `['items', 'units', 'value', 'low']`
2. The `_gather.php` view collects these per-system summaries
3. The `summary.php` view sums them using `array_sum()` for `value` and `units`, and adds `items` and `low` across systems

### Key source files

| File | Role |
|------|------|
| `src/Repositories/ProductRepository.php` | Core calculations for Materials & Books |
| `src/Repositories/AssetRepository.php` | Core calculations for Assets |
| `views/overview/_gather.php` | Per-system aggregation |
| `views/overview/summary.php` | Grand total display |
| `includes/dashboard_cards.php` | Per-system dashboard cards |
| `api/v1/stock.php` | REST API endpoint |
| `live.php` | Live stats JSON endpoint |
