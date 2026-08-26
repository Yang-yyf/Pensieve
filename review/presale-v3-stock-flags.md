# Review 报告 — 预售 v3（库存50 + 忽略库存同步 + 预售时限）

## 范围

`172b9c62..09ae32ca`（SG1+SG2+SG3），7 文件，+363/-13
data-service（upflags 代理）+ store-patrol（v3 pipeline）+ scheduler（天猫分支分流）

## Critical（阻断 PR）

- ❌ [技术] `TmallPresaleController.java` presaleV3/restoreV3：upflags(100/1) 失败、binding 失败均降级 warn 后仍记 SUCCESS；scheduler 幂等守卫（TMALL_PRESALE/TMALL_RESTORE SUCCESS）次日挡掉重试 → flags=100 永久残留（库存同步永久中断）或库存链接缺失不可自愈。upflags/binding/shiptime 均为绝对赋值，重试幂等安全。
- ❌ [技术] `PresaleProductTask.java` 场景 2 SQL：`MAX(product_id)` 与 `MAX(online_status)` 跨行拼接（GROUP BY book_id），同 bookId 多 mapping 行时 v2/v3 分流判断错乱，instock 行可能漏恢复库存同步。

## Warning（建议改但不阻断）

- ⚠️ 场景 1 候选口径 `product_id IS NOT NULL` 不区分 instock 与运营主动下架品（online_status 仅 0/1，但博库 flags 另有 2=下架）：进预售把 flags 置 100、出预售 flags=1 会把下架品强制上架。候选有 TMALL_PRESALE 记录限定，低概率，交用户定夺。
- ⚠️ `setSkuQuantity` 按 outer_id 定位 SKU 依赖既有 binding：从未绑定过的 instock 品该调用必失败。进预售前 binding 是否必然存在需线上验证（spec 已备降级 sku_id 路径）。

## Suggestion（可选）

- 💡 `TmallPresaleController` arrivalDate 正则放行 `2026-13-45`，`LocalDate.parse` 在 try 外抛异常 → 500。先 try-parse 或直接比较。
- 💡 StorePatrolClient v2/v3 方法同构可抽公共 POST helper（不做）。

## Pensieve 原则违反

- [x] **001-write-must-be-explicit**：未违反（本次仅写代码，无线上写操作；调度触发是已授权方案）
- [x] **002-verify-before-batch**：未违反（未批量执行）
- [x] **003-client-facing-sanitization**：未违反（无关）
- [x] **004-only-change-what-was-asked**：未违反（resolveSkusByOuterId 反查为 spec 内合理增强；审计沿用既有模式；边界 4 项均未越界）

## 完成度（vs spec）

- SG1 data-service upflags + 库存封装：**yes**（参数齐全，编译过）
- SG2 store-patrol v3 pipeline：**yes**（顺序正确 + 单测 5 例）
- SG3 scheduler 天猫分支：**partial**（候选口径/分流到位；"upflags 332 替代 deleteItem"选择保留——spec 原为问句，低风险）
- 边界：4 项全未做 ✓（publish/已删 23 本/PDD/mapping 表）
- 依赖：upflags ✓ / sku.quantity.update ✓（appkey 权限待线上验证）/ shiptime ✓ / binding ✓

## 结论

**已修复（f82db9c8，2026-08-26）**：C1 失败降级改整链 FAILED（upflags/binding/反查失败抛异常，scheduler 幂等守卫不挡 FAILED → 次日重试）；C2 GROUP BY+MAX 改 DISTINCT ON 同行取值；S1 arrivalDate try-parse。单测扩到 9 例全过，三模块编译过。**可以 PR。**
