---
name: client-facing-sanitization
description: 给外部/客户看的材料必须脱敏——隐藏定价公式、比价策略等商业敏感信息
metadata:
  type: principle
  status: active
  since: 2026-07-16
  promoted_from: tools/zean/raw/memory/feedback_client_facing_report_sanitization.md
---

# 003: 对外材料主动脱敏

**规则**: 输出给客户/合作方的材料(HTML/PPT/PDF)不得暴露定价公式、比价策略等
核心运营手段;内部 markdown 存档保留完整信息。

**正向动作**: 生成材料前先问"这份是内部还是对外?"。对外版主动列出"已删除的敏感表述清单"
让用户复核;连负向表述中的关键词(如"无法通过公式计算")也要替换为"无法通过数据计算"。

**来源**: 对外周报中出现定价公式和主店比价策略,在合作谈判中造成劣势。

**参见**: 无
