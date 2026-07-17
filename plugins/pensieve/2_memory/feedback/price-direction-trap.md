---
name: price-direction-trap
description: "\"X + Y（补齐）\"类调价描述，当 Y 列含正负号时方向极易理解反"
metadata:
  type: feedback
  date: 2026-06-24
  promoted: true
  promoted_to: 3_kernel/principles/002-verify-before-batch.md
---

# 调价公式方向陷阱

**场景**: 批量补齐亏损价。CSV 有 `actual_amount`（实付）和 `unit_profit`（单件利润，含正负号），
用户说"actual_amount + unit_profit（补齐，实际上是减法）"。

**错误**: 按字面执行 `actual + profit`。profit 为负数时（如 39.50 + (-12.37) = 27.13），
价格反而更低，几十个商品全部改成了更亏的价格。

**正确**: 用户原意是 `actual - profit`（减负数 = 加绝对值，39.50 - (-12.37) = 51.87，补齐到不亏）。
应先用一条样例反问用户："actual=39.50 profit=-12.37，目标价是 51.87 还是 27.13？"
确认后再批量。脚本先打印样例结果给用户看。

**后果**: 批量调反方向，两轮调价才修正（第二轮直接从错误价调到正确价即可，不必先回滚）。

**[[引用]]**: [[002-verify-before-batch]]
