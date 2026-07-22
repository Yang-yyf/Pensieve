---
name: batch-api-same-key-concurrent-collision
description: 批量调外部 API 时 CSV 按某 key 顺序排列 + 顺序并发 = 同 key 项同时打到 API 触发乐观锁（如淘宝"商品更新失败"）；解决：按 key 分组，组内串行、组间并发
metadata:
  node_type: memory
  type: pattern
  date: 2026-07-22
  promoted: false
---

# 批量调外部 API 同 key 并发撞锁

**场景**: 批量调外部 API（如淘宝 TOP API），CSV/数据源按某个 key（如 `num_iid`）顺序排列，记录连续。用 N 并发跑，前 N 条可能都属于同一个 key。

**错误**: 同 key 的多个记录被同时分发到不同 worker，同时打到 API。API 侧对同 key 有乐观锁/串行化要求（如淘宝对同 num_iid 的多 SKU 改价）→ 返回 "商品更新失败，请稍后重试" / "若有其他入口在本次提交前已经对该商品进行过编辑" 类乐观锁错误。

具体数据：3139 个 SKU 改价，10 并发，第一轮失败 68% 都是这类错误。

**正确**: 按 key 分组（`group-by-num` 模式），每个 key 的所有记录在一个 worker 内串行处理，不同 key 之间并发。`reprice_from_csv.py --group-by-num --workers 5` 已实现。

**后果**: 同 num_iid 多 SKU 改价，并发 5 + group-by-num 模式，688 个失败重试一次能搞定 677 个（98.4%）；并发 10 不分组，3139 个改价失败率 68%。

**参见**: `/Users/admin/Downloads/reprice_from_csv.py`、相关 memory [[topapiclient-item-price-no-stock-sku]]
