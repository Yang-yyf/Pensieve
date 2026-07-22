---
name: topapiclient-item-price-no-stock-sku
description: SKU 调价时若本次改的 SKU 本身 quantity=0，算 item_price 的 min 初值不能用本次新价——会触发淘宝"一口价必须等于有库存 SKU 价"错误
metadata:
  node_type: memory
  type: feedback
  date: 2026-07-22
  promoted: false
---

# TopApiClient 改 SKU 价时无库存 SKU 的 item_price 算错

**场景**: 调 store-patrol 的 `TopApiClient.updateSkuPrice`，给某个 num_iid 下的某个 SKU 改价。该 SKU 在淘宝侧 quantity=0（无库存）。

**错误**: `computeItemPriceAsSkuMinBySkuMin` 用 `BigDecimal minPrice = newPrice`（本次新价）做初值，然后遍历其他 SKU 取最低。如果本次 SKU 无库存 + 其他有库存 SKU 价格都高于新价，minPrice 停在新价。但新价对应的 SKU 无库存 → 不符合淘宝"item_price 必须等于有库存 SKU 价"规则 → 调用失败，错误：`IC_CHECKSTEP_ITME_NOT_IN_SKU_PRICE` / "一口价必须与商品销售规格列表里有库存的sku其中之一保持一致"。

**正确**: 算 item_price 前先查本次 SKU 当前是否有库存：
- 有库存：minPrice 初值用 newPrice（保留现有逻辑）
- 无库存：minPrice 初值不用 newPrice，只取其他有库存 SKU 的最低价；若其他都没库存才 fallback 到 newPrice

**后果**: 改价第一轮失败率从 30%+ 到接近 0；3139 个 SKU 改价，约 398 个由这个 bug 触发；多轮重试才能消化。

**参见**: store-patrol `PricingCalculator.java` `TopApiClient.java:262-293`、`/Users/admin/Downloads/reprice_from_csv.py` `--group-by-num`、相关 memory [[batch-api-same-key-concurrent-collision]]
