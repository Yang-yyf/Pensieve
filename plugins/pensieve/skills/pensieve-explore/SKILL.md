---
name: pensieve-explore
description: 改老功能前先调研+走读。两路并行：静态调研（调用链/依赖/近期改动）+ 动态走读（模拟程序运行、状态变化、副作用）。用户说 /pensieve-explore、"帮我看看 X 现状"、"我要改 X 先调研下"时触发
tags: [custom, pensieve, explore, investigation]
---

# /pensieve-explore — 调研 + 走读

改老功能前的**强制前置**。不调研直接改 = 找死。本 playbook 跑两路并行，把目标摸透，给出改造路径和风险点。

## 核心约束

**两路缺一不可**：
- 静态调研：grep / 调用链 / 文件结构（让你知道"代码长啥样"）
- 动态走读：模拟程序运行，追踪状态变化（让你知道"代码运行时长啥样"）

只做静态 = 像 v1 那样只 grep，没用。必须加上动态走读，模拟"用户点 X → 触发 A → 改 Y → 副作用 Z"。

## 流程

### 阶段 1：INTAKE（sub-goal: intake）

问一句话：**这次改 X，是因为什么？**（卡点 / 谁要 / 不做什么）

如果用户 prompt 里已经说清楚了，跳过此问。

### 阶段 2：SCOPE — 两路并行

#### sub-goal A：静态调研

调用 **Explore agent**，目标：摸清目标模块/功能的"代码地图"。

Explore agent 的 prompt 模板：

> 在当前项目里调研 <目标模块/函数/文件>：
> 1. 找入口点（API / 函数 / 文件位置）
> 2. 调用链向上：谁调用它？（列出 top 5 调用方）
> 3. 调用链向下：它调用谁？
> 4. 依赖：依赖的表 / 配置 / 外部接口 / 其他模块
> 5. 近期改动：git log --oneline -20 <相关文件>
> 6. 是否有现成测试覆盖
>
> 报告格式：分这 6 节，每节 3-5 行，不要长篇。

Explore agent 产出 → 写到 `{PENSIEVE_ROOT}/explore/<goal-name>/static.md`

#### sub-goal B：动态走读

调用 **bug-analyzer agent**（或 feature-dev:code-explorer），目标：模拟程序运行。

bug-analyzer agent 的 prompt 模板：

> 选一个入口（API / 用户操作 / 测试 case），模拟一次完整执行：
> 1. 入口：用户/系统做了什么动作？
> 2. 沿调用链向下走读，标注每一步：
>    - 函数签名 + 关键分支
>    - 状态变化（读了什么 / 写了什么 / 缓存了什么）
>    - 副作用（DB 写 / 消息发送 / 文件 IO / 外部 API 调用）
>    - 可能的异常路径
> 3. 最后给出"如果我改 X，影响范围是 Y"的预测
>
> 报告格式：执行路径编号列出（步骤 1→2→3），每步标注状态变化/副作用/异常。

bug-analyzer agent 产出 → 写到 `{PENSIEVE_ROOT}/explore/<goal-name>/dynamic.md`

### 阶段 3：SPEC — 汇总成改造路径

合并两路产出，写到 `{PENSIEVE_ROOT}/explore/<goal-name>/summary.md`：

```markdown
# <目标> 调研汇总

## 现状
<3-5 句话描述这个模块/功能现在是怎么工作的>

## 代码地图
- 入口：<文件:行号>
- 关键调用方：<top 3>
- 关键依赖：<表/接口/模块>

## 执行路径
<从 dynamic.md 摘最关键 1-2 条路径，标注状态/副作用>

## 改造路径建议
1. <改动点 1>
2. <改动点 2>
...

## 风险点
- ⚠️ <耦合重的位置>
- ⚠️ <没测试覆盖的位置>
- ⚠️ <副作用深的位置>
```

同时初始化 spec 文件 `{PENSIEVE_ROOT}/spec/<goal-name>.md`，写入 `## 现状摘要` 段（引用 summary.md）。

### 阶段 4：WRAP

1. 更新 `{PENSIEVE_ROOT}/.state/current.json`：
   ```json
   {
     "active_goal": "<goal-name>",
     "active_phase": "EXPLORE_DONE",
     "explore_summary": "<path>",
     "last_updated": "<ISO time>"
   }
   ```
2. 给用户输出：summary.md 的核心内容 + 推荐改造路径
3. 提示："接下来可以 /pensieve-spec 写需求，或直接 /pensieve-dev 开干（如果改造路径很清晰）"

## 不做什么

- **不写代码**——explore 是只读的，写代码去 /pensieve-dev
- **不做需求分析**——边界/输入输出去 /pensieve-spec
- **不跳过动态走读**——只静态调研不算 explore
