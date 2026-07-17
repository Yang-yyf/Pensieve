---
name: keep-changes-small
description: 每次修改只做一个语义变更，方便 review 和回退
metadata:
  type: principle
  status: example
  since: 2026-07-16
  promoted_from: null
---

# 001: 每次修改只做一个语义变更

**规则**: 一次 commit 只改一件事。重构 + 新功能 = 两个 commit。

**正向动作**: 动手前先把变更拆成"本次 commit 只做 X",其他改动 stash 或下次再提;commit message 只描述 X。

**来源**: 多次混合 commit 导致回退时丢失有用代码。

**参见**: 无

---

> ⚠️ 这是示例文件。fork 后请删除,替换为你自己的原则。
