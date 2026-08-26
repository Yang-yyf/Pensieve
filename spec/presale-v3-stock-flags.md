# 预售 v3：库存 50 + 忽略库存同步 + 预售时限（天猫在架品）

## 背景

老方案 DELIST（物理删商品）损失权重；v2 shiptime 只解决了"在架商品设预售时限"，但**库存 0 的商品无法预售**（缺货 publish 上架被拒，"商品在的" instock 品也无法真正卖）。
博库提供 `upflags.php`（2.16）：`flags=100 忽略库存同步` / `flags=1 在架(恢复)` / `flags=332 待删除`。
方案：**不依赖缺货上架**——商品保持 instock（不上架），手动设库存 50 + 忽略库存同步 + 预售时限；到货后删时限 + 恢复同步 + binding 建库存链接，有货后自然可卖。

## 输入 / 输出

- 输入：未到货等待表 `bm_wdhddspb` 中"商品在的"天猫商品（num_iid 存在，approveStatus=instock）
- 输出：
  - 进预售：天猫库存 50 → `upflags flags=100` → `tmall.item.shiptime.update` 设发货时限（=到货日+缓冲，≥T+3）
  - 出预售：删 shiptime → `upflags flags=1` → `binding` 建库存链接
  - 审计：沿用 `t_presale_action_log`（TMALL_PRESALE / TMALL_RESTORE）

## 边界

- 在做：data-service 天猫库存修改方法 + upflags 封装；store-patrol 进/出预售链路；scheduler PresaleProductTask 场景 1/2 天猫分支改造
- 不做：
  - 缺货上架（publish）——不在本方案范围
  - 商品已删的（23 本）恢复——等货到走老铺货链路，另有 P1 心跳 NULL 修复（后续单独处理）
  - PDD 侧库存/flags——本方案只做天猫（PDD 预售已有 pre_sale_time 链路）
  - 不改 mapping 表

## 依赖

- 博库 `upflags.php`（2.16）：`spbs/dpbh/num_iid/flags`，flags 100=忽略库存同步、1=在架、332=待删除
- 天猫库存接口：`taobao.sku.quantity.update`（按 num_iid+outer_id=bookId 定位 SKU 设 quantity）——**未封装，需新写**
- 已有：shiptime 设/删（TopApiClient.setShipmentTime）、binding（BookuuApiClient.binding）

## Sub-goals

1. **SG1: data-service 加 upflags + 天猫库存端点** — BookuuApiClient 加 upFlags()；DataController 加 `/products/mapping/upflags`；TopApiClient 加 setSkuQuantity（taobao.sku.quantity.update 走 proxy 透传）。完成判据：编译过，端点可调
2. **SG2: store-patrol 预售 v3 pipeline** — 进预售：setSkuQuantity(50) → upflags(100) → shiptime；出预售：删 shiptime → upflags(1) → binding。完成判据：编译过 + 单测（mock 顺序）
3. **SG3: scheduler PresaleProductTask 天猫分支改造** — 场景 1 调 v3 进预售（候选改为"商品在的"：num_iid 有效即 instock 商品）；场景 2 调 v3 出预售；老方案 DELIST 分支退役（flags=332 或保留？—— 用 upflags 332 替代 deleteItem）。完成判据：编译过
4. **SG4: 编译验证 + commit** — store-patrol + scheduler + data-service 三模块编译；分 commit 落地

## 完成标准

- [x] 4 个 sub-goal 全部 commit 落地
- [x] store-patrol + scheduler + data-service 编译全过
- [x] spec 与代码一致

## 待确认（写码前）

- taobao.sku.quantity.update 是否需 sku_id 而非 outer_id（淘宝文档：支持 outer_id 定位）——**已按 outer_id 实现**（setSkuQuantity），验证时若失败降级 sku_id
- 进预售候选口径："商品在的" = mapping 有 num_iid 且 product-detail 存在（instock/onsale 都算）？—— **已实现**：mapping.product_id 非空即算（线上 1000037 确认：未到货 61 本，其中 online_status=0 的 59 本走 v3、online_status=1 的 2 本走 v2 shiptime）

## 落地记录（2026-08-26）

- e84a3c72 SG1: data-service 博库 upflags 代理（2.16）
- 8042962c SG2: store-patrol 预售 v3 pipeline（setSkuQuantity/upFlags/controller/单测5例）
- 09ae32ca SG3: scheduler PresaleProductTask 天猫分支 v3（instock 进预售/到货恢复按 online_status 分流）
- 三模块编译全过（data-service/store-patrol/scheduler），store-patrol 单测 5/5
