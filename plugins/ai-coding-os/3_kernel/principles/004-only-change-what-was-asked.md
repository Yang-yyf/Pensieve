---
name: only-change-what-was-asked
description: 只改用户明确要求改的，不自作主张扩大变更范围
metadata:
  type: principle
  status: active
  since: 2026-07-16
  promoted_from: tools/zean/raw/memory/feedback_only-change-what-was-asked.md
---

# 004: 一次只改被要求改的范围

**规则**: 只修改用户明确指定的模块/功能,不"顺手"改相关但未被要求的部分。
不同语义的变更(重构、新功能、bug fix)分开 commit。

**正向动作**: 动手前先列出"本次将改 X、Y",让用户确认范围;
Edit/Write 前自问"这次改动是否在列出的范围内?",超范围发现另外记录,不顺手改。

**来源**: 用户对不同功能有不同模型策略,擅自改了未被要求的模块配置引起不满。

**参见**: 无
