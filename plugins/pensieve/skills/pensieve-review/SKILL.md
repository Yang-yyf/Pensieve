---
name: pensieve-review
description: 走读 diff（不是走形式）。两路并行：路径 A 走读 diff 找 bug/安全问题；路径 B 检查是否符合 spec、有无遗漏边界、有无超范围变更。用户说 /pensieve-review、"帮我审一下""review 一下""要 PR 了"时触发
tags: [custom, pensieve, review, quality]
---

# /pensieve-review — 走读 diff

不是橡皮图章。两路并行：技术走读（diff 本身）+ 语义走读（diff 是否实现了 spec、有无超范围）。

## 流程

### 阶段 1：INTAKE — 确定 review 范围

默认范围：**当前分支 vs main 的全部 diff**。

也支持：
- `/pensieve-review <PR 编号>` → 用 gh 拉 PR diff
- `/pensieve-review <commit-hash>` → 单 commit
- `/pensieve-review <branch1>..<branch2>` → 任意区间

通过 git diff 拿到改动文件列表 + 行数统计，先给用户一个 overview：
```
本次 review 范围: <range>
改动文件 <N> 个:
  - <file1> (+<X> -<Y>)
  - <file2>
  ...
```

### 阶段 2：SCOPE — 两路并行

#### sub-goal A：技术走读

调用 **feature-dev:code-reviewer agent**（或 code-reviewer-twin）：

> 走读以下 diff，按 critical / warning / suggestion 分级报问题：
>
> <diff 内容，或者告诉它 git diff 命令让它自己跑>
>
> 检查项：
> 1. 是否符合 spec（spec 路径: <spec_path>）
> 2. 边界条件 / null 处理 / 异常路径
> 3. 安全：SQL 注入 / XSS / 命令注入 / 路径穿越 / 敏感信息泄露
> 4. 复用 / 简化：有没有重复代码、能不能用现有工具
> 5. 并发安全（如果涉及共享状态）
>
> 严格按上面 5 项报，每项给具体 file:line + 问题 + 建议。

#### sub-goal B：语义走读

调用 **feature-dev:code-reviewer agent**（不同 instance）：

> 这次改动对应的 spec 在 <spec_path>。检查：
> 1. spec 的"完成标准"每条是否都体现在 diff 里
> 2. spec 的"边界 → 不做"项有没有被偷偷做了
> 3. 有没有引入 spec 里没提到的额外变更（scope creep）
> 4. spec 里写的"依赖"是否真的被处理
>
> 报告：逐项 yes/no/partial，partial 要说明。

### 阶段 3：SPEC — 汇总 + Pensieve 原则检查

合并两路产出，写到 `{PENSIEVE_ROOT}/review/<goal-name>.md`：

```markdown
# Review 报告 — <goal-name>

## 范围
<range / 改动文件数 / 总行数>

## Critical（阻断 PR）
- ❌ [技术] <file:line> <问题>
- ❌ [语义] <完成标准 X 未满足>

## Warning（建议改但不阻断）
- ⚠️ <file:line> <问题>

## Suggestion（可选）
- 💡 <file:line> <建议>

## Pensieve 原则违反
（自动检查 4 条原则是否被本次 diff 违反）

- [ ] **001-write-must-be-explicit**：是否包含未明确的线上写操作？
- [ ] **002-verify-before-batch**：批量操作前有没有样例对齐？
- [ ] **003-client-facing-sanitization**：对外材料是否脱敏？
- [ ] **004-only-change-what-was-asked**：是否超范围变更？

## 完成度（vs spec）
<逐条列 spec 的完成标准，标 yes/no/partial>
```

### 阶段 4：WRAP

1. 输出 review 报告的核心：
   ```
   Critical: <N> 条（阻断 PR）
   Warning:  <N> 条
   Pensieve 原则违反: <N> 条
   完成度: <X>/<Y>
   ```
2. 列 Critical 详细
3. 如果有 Critical 或原则违反 → 明确说"别 PR，先改"
4. 全 clean → "可以 PR 了"
5. 更新 current.json：
   ```json
   {
     "active_phase": "REVIEWED",
     "review_path": "<path>"
   }
   ```

## 与原生 code-reviewer 的关系

主要复用 `feature-dev:code-reviewer`。如果需要带 Pensieve 原则审查，改用项目自己的 `code-reviewer-twin` agent（它会读 `3_kernel/principles`）。

## 关键约束

- **两路并行**——不能只走技术不走语义
- **Pensieve 原则检查是硬性的**——4 条原则违反任一 = critical
- **不放过 Critical**——critical 不清零不允许 PR
- **不替用户决定**——找到问题报出来，改不改用户决定
