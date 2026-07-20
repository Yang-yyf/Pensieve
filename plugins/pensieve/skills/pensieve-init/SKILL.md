---
name: pensieve-init
description: 首次配置或重新配置 Pensieve。检查 pointer、可选启用项目级 kernel、在 CLAUDE.md 写入 Pensieve 配置段(Sub-Agent Context Block 模板 + 常用命令)。用户说 /pensieve-init、"配置 Pensieve""初始化 Pensieve""Pensieve 怎么用"时触发
tags: [pensieve, meta, init]
---

# /pensieve-init — Pensieve 配置向导

首次安装后、或换项目时、或想重新配置时运行。一次性完成:

1. 检查/创建 Layer 1 pointer 文件
2. 询问是否为本项目启用项目级 kernel(Layer 1.5)
3. 在 CLAUDE.md 写入 Pensieve 配置段(含 Sub-Agent Context Block 模板、常用命令清单)

## 流程

### 1. 欢迎(检测首次)

读 `~/.claude/pensieve.path` 是否存在且路径有效:
- 不存在或无效 → 首次配置,先给一段 30 秒介绍(见下方"Pensieve 简介")
- 已存在且有效 → 跳过欢迎,简短说"已检测到 Layer 1 源仓库:`<路径>`,开始重新配置"

### 2. Layer 1 pointer 配置

读 `~/.claude/pensieve.path`:
- 不存在/路径无效 → 询问"你的 Pensieve Layer 1 仓库本地绝对路径?"(例如 `/Users/xxx/pensieve-yifei`)
  - 用户给出后,验证 `[path]/plugins/pensieve` 目录存在,写入 pointer 文件
- 已存在 → 显示当前指向,问"更新还是保持?"用户选保持则跳过

### 3. 项目级 kernel(Layer 1.5)询问

问:"本项目要启用项目级 kernel 吗?项目级 kernel 用来存这个项目专属的架构决策、契约、领域知识,SessionStart 会自动叠加在 Layer 1 原则上。"

- 是 → 问"kernel 目录绝对路径?",验证目录存在,写入 `${CLAUDE_PROJECT_DIR}/.claude/pensieve-project.path`
- 否 → 跳过(后续可手动建 marker 文件启用)

### 4. 写入 CLAUDE.md Pensieve 段

检查当前项目的 `CLAUDE.md`:

- **不存在**:问"是否创建 CLAUDE.md?" 是 → `touch CLAUDE.md` 后追加;否 → 跳过本步,打印建议让用户手动加
- **存在**:检查是否已有 `## Pensieve 配置` 段
  - **有**:问"已存在 Pensieve 配置段,覆盖还是取消?"覆盖 → 用新内容替换该段(从 `## Pensieve 配置` 到下一个 `## ` 之间);取消 → 跳过
  - **没有**:在文件末尾追加 `\n\n` + 配置段

**配置段模板**(根据上面 answer 填充,勿动缩进与 fence):

````markdown
## Pensieve 配置

> 由 `/pensieve-init` 生成。重新配置运行 `/pensieve-init`,手动编辑直接改下方值。
> Pensieve 把 AI 协作中的经验/踩坑/判断从"脑子里"搬到"git 仓库里",原则通过 SessionStart 自动注入每个 session 作为 AI 行为约束。

### 当前配置

- **Layer 1 源仓库**: `<填入 PENSIEVE_ROOT>` — 原则与 memory 实际存这里,通过 `~/.claude/pensieve.path` 定位
- **项目级 kernel (Layer 1.5)**: <未启用 | 已启用 → `<填入路径>`> — 项目专属架构决策,marker 在 `.claude/pensieve-project.path`
- **审查提醒节奏**: daily: on / weekly: off / monthly: on
  - 关 daily:运行 `/pensieve-retrospect --daily` 记一笔后当天不再提醒
  - 关 monthly:把 `<PENSIEVE_ROOT>/plugins/pensieve/growth-log.md` 的 `last_monthly` 改成今天
- **原则触发模式**:宽松(Claude 提示冲突后让用户决定);想改严格(主动拦截),把本行改为"严格"

### Sub-Agent Context Block

调用任何 Agent 工具(`code-reviewer-twin` 等 subagent)前,**必须** prepend 本段到 sub-agent 的 prompt 里:

```
当前项目: <由主 session 在调用前更新>
当前服务: <同上>
当前任务: <同上>
相关文件: <同上>
```

> Sub-agent 起独立 context,没有主 session 的对话历史。缺这段它会凭空猜项目背景。
> **强约束**:必须 prepend,**不得省略、不得仅摘要**。

### 常用命令

- `/pensieve-learn <描述>` — 记录踩坑/偏好/约定(也可不描述,扫对话找候选)
- `/pensieve-promote <memory-path>` — 把已验证 2+ 次的 memory 升级为原则
- `/pensieve-forge <领域>` — 把原则+偏好锻造成你专属的 skill
- `/pensieve-retrospect --daily | --monthly` — 日度笔记 / 月度审查清理
- 召唤 `code-reviewer-twin` agent — 带 Pensieve 原则的代码审查
- `/pensieve-init` — 重新配置(本命令)

详见 `zean/docs/2026-07-16-pensieve-design.md`。
````

### 5. 总结

打印:
- 配置摘要(Layer 1 路径、项目级 kernel 状态、CLAUDE.md 段已写)
- 下一步建议:"现在试试 `/pensieve-learn`——扫一遍最近的对话,把值得记的东西挑出来。或者 `/pensieve-forge` 看看能从已有原则锻造出什么"

## 边界

- 用户拒绝任何一步 → 跳过该步,继续下一步,不要追问
- pointer 文件已存在且有效 → 步骤 2 跳过,只显示当前指向
- CLAUDE.md 是只读或用户明确不让改 → 步骤 4 跳过,打印配置段让用户手动复制
- 项目级 kernel 目录路径无效 → 报错,问"重输还是跳过?"

## Pensieve 简介(用于步骤 1 首次)

> Pensieve 取自 Harry Potter 的冥想盆(Pensieve):把记忆从脑中抽出存进盆里,需要时回头审视、交叉对照。
>
> **怎么用**:`/pensieve-learn` 记下踩坑/偏好/约定,`/pensieve-promote` 把已验证的模式升级为原则,`/pensieve-forge` 把积累锻造成你专属的 skill,SessionStart hook 自动注入原则 + 偏好 + 约定每个 session,UserPromptSubmit hook 按关键词主动召回相关记忆。
>
> 四种 memory 类型:feedback(踩坑)、pattern(规律)、**preference(你的工作风格)**、**convention(项目/代码规矩)**。只有 feedback 是从错误学,其他三种是"你本来就是这样工作的"。
