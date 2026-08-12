# Pensieve v2

**一个程序员 agent**——跨完整工作流的副驾，不在流程外面。

v1 是个"事后记忆库"，离实际开发太远。v2 把方向重写：站在写代码的关键时刻——
改老功能时主动 explore、新需求时主动 spec、完成时主动 review。每一步是 sub-goal，每个 sub-goal 一个 commit。

## 4 个 playbook（核心能力）

| 命令 | 做什么 |
|------|--------|
| `/pensieve-explore` | 改老功能前调研 + 走读代码（静态调研 + 动态模拟运行） |
| `/pensieve-spec` | 把模糊需求写成可执行 spec（背景/输入输出/边界/完成标准） |
| `/pensieve-dev` | 拆 sub-goals + 执行（写代码+编译+测试+commit） |
| `/pensieve-review` | 走读 diff（技术走读 + 语义走读 + 原则检查） |

## 总入口

- `/pensieve` — 空参给状态卡片；有 prompt 自动路由到对应 playbook

## 主动在场

UserPromptSubmit hook 扫关键词，命中场景输出一行提醒（不强介入）：
- "改现有 X" → 提示 `/pensieve-explore`
- "实现新 Y" → 提示 `/pensieve-spec`
- "改完了/PR" → 提示 `/pensieve-review`

## 底层（复用原生 agent，不重写）

- `Explore agent` → 静态调研
- `bug-analyzer agent` → 动态走读（模拟执行路径）
- `feature-dev:code-architect` → 需求架构
- `feature-dev:code-reviewer` → diff 走读
- `code-reviewer-twin`（自带）→ 带 Pensieve 原则的 review

## 持久化

```
plugins/pensieve/
├── spec/<goal-name>.md          # 每个目标的合约
├── explore/<goal-name>/
│   ├── static.md                # 静态调研产出
│   ├── dynamic.md               # 动态走读产出
│   └── summary.md               # 汇总
├── review/<goal-name>.md        # review 报告
├── .state/current.json          # 跨 session 状态
├── 3_kernel/principles/         # 4 条硬约束（review 时检查）
├── 2_memory/                    # 跨会话知识（保留 v1，作为 agent 的知识底座）
└── skills/                      # 5 个 skill 文件
```

## 约束（贯穿所有 playbook）

1. 所有能力跑在 spec+goal 引擎上，每步是 sub-goal，每个 sub-goal 一个 commit
2. explore 必须两路：静态调研 + 动态走读（缺一不可）
3. review 必须两路：技术走读 + 语义走读（缺一不可）
4. 改老功能必须有 explore 前置，没 explore summary 不接 spec

## v1 → v2 变化

**砍掉**：`/pensieve-learn`、`/pensieve-promote`、`/pensieve-forge`、`/pensieve-retrospect`、`/pensieve-init`
（这套"记忆库 + 反思"形态不实用，离开发流程太远）

**保留**：`/pensieve-goal`（作为引擎参考，不暴露）、4 条 kernel 原则、2_memory（作为知识底座）

**新增**：4 个 playbook（explore/spec/dev/review）+ `/pensieve` 总入口 + 轻量关键词 hook

## 安装

```bash
# 1. fork & clone
git clone git@github.com:Yang-yyf/Pensieve.git

# 2. 注册为 marketplace
/plugin marketplace add /path/to/Pensieve
/plugin install pensieve@pensieve

# 3. 登记 fork 路径（写入 fork 本地路径到 pointer 文件）
echo "/path/to/Pensieve" > ~/.claude/pensieve.path
```
