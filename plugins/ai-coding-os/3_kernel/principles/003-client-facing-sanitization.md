---
name: client-facing-sanitization
description: 给外部/客户看的材料必须脱敏——隐藏定价公式、比价策略等商业敏感信息
metadata:
  type: principle
  status: active
  since: 2026-07-16
  promoted_from: tools/zean/raw/memory/feedback_client_facing_report_sanitization.md
---

# 003: 对外材料脱敏

**规则**: 输出给客户/合作方的材料（HTML/PPT/PDF）不得暴露定价公式、
比价策略等核心运营手段；内部 markdown 存档保留完整信息。
生成对外材料前主动检查敏感表述，连负向表述中的关键词（如"公式"）也要规避。

**来源**: 对外周报中出现定价公式和主店比价策略，会在合作谈判中造成劣势。
内外两个版本口径必须分离。

**[[引用]]**: 无
