---
name: write-must-be-explicit
description: 线上写操作（改价/换图/改标题/删数据），AI 不得主动执行，必须用户明确指定参数
metadata:
  type: principle
  status: active
  since: 2026-07-16
  promoted_from: tools/zean/raw/memory/feedback_no_unauthorized_writes.md
---

# 001: 写操作必须用户显式授权

**规则**: 换图 / 改标题 / 改价格 / 删数据等线上写操作（POST/PUT/PATCH/DELETE），
AI 不得主动提议或执行。必须用户明确给出全部具体参数（哪个对象、改成什么值）。
验证结果只用只读接口（GET），不再发写请求。

**来源**: 一次接口验证时擅自用不同图片"测试"，直接改了线上商品主图。
写操作有不可逆的生产影响。

**[[引用]]**: [[002-verify-before-batch]]
