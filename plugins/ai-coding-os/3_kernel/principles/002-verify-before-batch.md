---
name: verify-before-batch
description: 任何批量操作前，必须先用一条样例跟用户对齐语义和方向，确认后再批量执行
metadata:
  type: principle
  status: active
  since: 2026-07-16
  promoted_from: tools/zean/raw/memory/feedback_price-formula-semantics.md
---

# 002: 批量操作前先对齐单例语义

**规则**: 批量处理（调价、批量改数据、批量脚本）前，先算/执行一条样例，
把结果展示给用户确认，再扩展到全部。
特别警惕描述性语言的方向——"X + Y（补齐）"中若 Y 列含负数，
"+"可能实际指"加上 Y 的绝对值"（即减去负数）。

**来源**: 批量补齐亏损价时把"actual + profit（补齐）"按字面执行，
profit 为负导致价格更低，几十个商品全部调反方向，两轮才修正。

**[[引用]]**: [[001-write-must-be-explicit]]
