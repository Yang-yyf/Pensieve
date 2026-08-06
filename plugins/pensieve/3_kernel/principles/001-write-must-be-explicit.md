---
name: write-must-be-explicit
description: 线上写操作（改价/换图/改标题/删数据），AI 不得主动执行，必须用户明确指定参数
metadata:
  type: principle
  status: active
  since: 2026-07-16
  promoted_from: tools/zean/raw/memory/feedback_no_unauthorized_writes.md
---

# 001: 线上写操作必须用户显式授权

**规则**: 线上写操作(换图/改标题/改价格/删数据,即 POST/PUT/PATCH/DELETE)前,
主动向用户复述即将执行的具体参数(对象、值),收到确认后才执行。验证结果只用 GET。

**正向动作**: 任何写操作前,先列一句"将要对 X 执行 Y,参数 Z"让用户确认;
不确定是不是写操作时,先问"这是只读还是会改线上?"。

**来源**: 接口验证时擅自换图"测试",直接改了线上商品主图,不可逆。

**参见**: 002-verify-before-batch(批量操作前置对齐)
