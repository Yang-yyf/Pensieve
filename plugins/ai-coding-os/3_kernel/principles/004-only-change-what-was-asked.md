---
name: only-change-what-was-asked
description: 只改用户明确要求改的，不自作主张扩大变更范围
metadata:
  type: principle
  status: active
  since: 2026-07-16
  promoted_from: tools/zean/raw/memory/feedback_only-change-what-was-asked.md
---

# 004: 只改被要求改的

**规则**: 只修改用户明确指定的模块/功能，不"顺手"改相关但未被要求的部分。
每次动手前确认范围："用户只要求改 X"就只改 X，不延伸到 Y。
重构 + 新功能等不同语义的变更分开提交。

**来源**: 用户对不同功能有不同的模型策略，擅自改了未被要求的模块配置引起不满。

**[[引用]]**: 无
