---
name: pensieve-spec
description: 把模糊需求写成可执行 spec（背景/输入输出/边界/依赖/完成标准）。改老功能必须先有 explore summary，新功能要调研现有类似实现。用户说 /pensieve-spec、"写个需求"、"把这事拆清楚"时触发
tags: [custom, pensieve, spec, requirements]
---

# /pensieve-spec — 需求分析

把"我想做 X"变成可执行的合约。spec 落盘是硬要求——没 spec 不进 dev。

## 流程

### 阶段 1：INTAKE

一句话问 WHY：**这次做 X，是因为什么？**
- 卡点（现在的功能哪里不行）
- 谁要（业务方/用户/自己）
- 不做什么（明确排除什么）

prompt 已经说清楚就跳过。

### 阶段 2：SCOPE — 区分新/老功能

#### 改老功能（必须先 explore）

检查 `{PENSIEVE_ROOT}/.state/current.json` 的 `active_goal` 是否有对应的 explore summary：
- **有** → 读 summary，作为 spec 的 `## 现状摘要` 段
- **没有** → 提示用户："这是改老功能，需要先 /pensieve-explore 调研，要不要现在跑？" 用户同意则**联动调用 /pensieve-explore**，跑完再回来写 spec

#### 新功能（调研类似实现）

调用 **Explore agent**：
> 在当前项目找类似的现有实现（功能/模式相近的）：
> 1. 有没有现成的可复用？
> 2. 项目里类似功能是怎么组织的？（目录结构/命名约定/接口风格）
> 3. 有没有可参考的 spec/设计文档？
>
> 简短报告，3-5 行。

### 阶段 3：SPEC — 落盘

写到 `{PENSIEVE_ROOT}/spec/<goal-name>.md`：

```markdown
# <goal 标题>

## 背景
<1-2 句：为什么做，卡在哪>

## 现状摘要（仅改老功能有）
<从 explore summary 摘核心 2-3 句，链接到 explore/<goal-name>/summary.md>

## 输入 / 输出
- 输入：<需要的数据/接口/前置条件>
- 输出：<交付物：代码/表/接口/配置>

## 边界
- 在做：<明确范围>
- 不做：<明确排除，含发现的超范围项>

## 依赖
- <需要的上下游、表、外部接口>

## 完成标准
- [ ] 所有 sub-goal commit 落地
- [ ] compile + 单测全过
- [ ] spec 与代码一致（变更先改 spec）
- [ ] （可选）review 通过

## Sub-goals
（由 /pensieve-dev 填写）
```

### 阶段 4：WRAP

1. 把 spec 路径告诉用户，让他**审 spec**
2. 用户审通过 → 更新 current.json：
   ```json
   {
     "active_goal": "<goal-name>",
     "active_phase": "SPEC_READY",
     "spec_path": "<path>"
   }
   ```
3. 提示："spec 落地了，可以 /pensieve-dev 拆 sub-goals 开干"

## 关键约束

- **SPEC 必须落盘**——没 spec 文件，dev 不接
- **改老功能必须有 explore**——spec 里的"现状摘要"段不能为空
- **边界段必须写"不做"**——防止 scope creep
- **sub-goals 段本 skill 不填**——留给 /pensieve-dev 拆

## 与原生 feature-dev:code-architect 的关系

复杂的架构决策可以**额外**调用 `feature-dev:code-architect` agent 辅助设计，但 spec 文件本身由本 skill 主导写。
