---
name: pensieve-promote
description: 把已积累的 memory 升级为 kernel 原则或试探规则。用户说 /pensieve-promote 或"升级为原则""通用化""这条可迁移""提炼"时触发
tags: [pensieve, meta, promote]
---

# /pensieve-promote — 飞跃

## Pensieve 源仓库定位

读 `~/.claude/pensieve.path` 第一行得到 `PENSIEVE_ROOT`(不存在则询问用户并写入)。相对路径相对于 `PENSIEVE_ROOT/plugins/pensieve/`,git 操作在 `PENSIEVE_ROOT` 中执行。绝不写插件安装缓存。

## principles vs heuristics 定义

- **principle**(原则):跨所有项目成立的硬约束。违反会造成真实损害。例:"写操作必须用户显式授权"。每次只能少几条,值得占 SessionStart token
- **heuristic**(试探规则):经验法则,通常对但有例外。例:"优先 Alpine 而非 Ubuntu 基础镜像"。可多可少,作参考
- 区别:principle 是"必须",heuristic 是"建议"。不确定时先放 heuristics,等再积累证据再升级 principle

## 触发

用户说 `/pensieve-promote <memory-path>`。

## 交互原则

每一步展示中间结果,等用户确认。写文件前所有步骤可回退。

## 执行逻辑

### 步骤 A:读 memory → 展示

读指定 memory 文件。支持两种路径:
- Layer 1:`2_memory/xxx/xxx.md`(相对于 `PENSIEVE_ROOT/plugins/pensieve/`)
- 项目级:`.claude/memory/xxx/xxx.md`(相对于 `CLAUDE_PROJECT_DIR`)

展示内容摘要:"这条 memory 讲的是:xxx。对么?"

### 步骤 B:判断门槛 → 等确认

遍历相关目录找语义相似的条目:
- `PENSIEVE_ROOT/plugins/pensieve/2_memory/feedback/`
- `${CLAUDE_PROJECT_DIR}/.claude/memory/feedback/`

对每个文件,自问:"这条的根本模式(不是表面场景)是否相同?"

- 只找到当前这一条 → 建议拒绝:"目前只观察到 1 次,积累更多验证后再升级,或者你非要现在升就告诉我 bypass"
- 找到 2+ 次相似 → 列出来:"找到 N 条相似。继续?"
- 用户明确 bypass → 不管次数,继续

### 步骤 C:提取 + 写草稿 → 确认

按下方模板写原则草稿:
- 去项目名、时间、技术栈;去项目风味用词("线上"→"生产","博库"→"外部")
- 正文 < 200 字
- 编号:扫 `3_kernel/principles/[0-9]*-*.md` 找最大 N + 1(三位补零)
- **参见**:扫已有原则,自问"新原则和哪条共享触发条件或后果?"列出;无相关则"无"

展示草稿:"这是原则草稿——标题/规则/正向动作/参见 都对么?"

### 步骤 D:判断位置 → 确认

> 这条应该放 **[principles(硬约束) / heuristics(经验法则)]** —(理由)?

用户确认或改选。

### 步骤 E:回填原 memory + 写文件 → 最后确认

展示要做的三件事:
1. 写原则文件:`<path>`
2. 回填原 memory metadata:加 `promoted: true` + `promoted_to:`
3. git commit

> 最后确认:执行以上三步?

用户说"好" → 执行。若源是项目级的,项目仓库也单独 commit 标记变更。

## 原则文件模板

```markdown
---
name: <kebab-case-slug>
description: <一句话描述,便于检索>
metadata:
  type: principle
  status: active
  since: YYYY-MM-DD   # promote 当天日期(原则进入 kernel 的生日),不是事故首现日期
  promoted_from: <原 memory 路径>
---

# <NNN>: <原则标题>

**规则**: <可执行的命令式表述,说明边界和触发条件>

**正向动作**: <该做什么,不是不该做什么。具体到一句可执行的话>

**来源**: <真实事故的一句话摘要,不要过度具体>

**参见**: <关联原则的文件名,自然语言简短说明关联,如"参见 002-verify-before-batch(批量前置对齐)">。**禁止用 [[xxx]] wiki 语法,Claude 无法解析>
```

## Bootstrapping 例外

首批 kernel 允许 bypass"2 次验证"规则——系统第一条原则天然无法自举。
用户在初始化时手动确认即可。
