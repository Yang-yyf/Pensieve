---
name: learn
description: 记录一次踩坑/经验/教训,或从对话中提炼可复用模式。用户说 /pensieve:learn、或"记录一下""踩坑""教训""经验""刚才那个错"时触发
tags: [os, meta, learn]
---

# /pensieve:learn — 记录经验

## Pensieve 源仓库定位

读 `~/.claude/pensieve.path` 第一行得到 `PENSIEVE_ROOT`(不存在则询问用户并写入)。相对路径相对于 `PENSIEVE_ROOT/plugins/pensieve/`,git 操作在 `PENSIEVE_ROOT` 中执行。绝不写插件安装缓存——那里改了不进成长曲线。

## 触发

用户说 `/pensieve:learn` 或 `/pensieve:learn <描述>`。

## 执行逻辑

1. 如果用户提供了描述,直接处理。
   否则**先扫当前 session 最近的对话**,看是否有可提炼的经验(用户刚纠正过 AI、刚发现 bug、刚复盘某个判断、AI 刚才走错方向被叫停等)。
   - 有候选 → 列出来让用户挑:"看起来这几处可能是经验,记哪个?"(给出 2-3 个候选,每个一句话)
   - 没候选 → 问"要记录什么经验?"
2. 从描述中去掉项目名、时间戳、具体数据
3. 保留元结构：
   - **场景**: 在做什么的时候
   - **错误**: 发生了什么问题（或 AI 做了什么不对的事）
   - **正确**: 应该怎么做
   - **后果**: 不这样做会怎样
4. **判断目标层级**（关键）：
   - **跨项目**（方法论、协作原则、通用陷阱，换项目也成立）→ `PENSIEVE_ROOT/plugins/pensieve/2_memory/feedback/<slug>.md`
   - **项目特定**（某项目的端口、API 坑、配置 idiosyncrasy，换项目就无意义）→ `${CLAUDE_PROJECT_DIR}/.claude/memory/feedback/<slug>.md`
   - 判断不准时问用户："这条经验是通用的，还是只在这个项目成立？"
5. **判断类型**(参见下方"feedback vs pattern"定义):
   - feedback → `feedback/`
   - pattern → `patterns/`
6. 检查目标目录是否已有类似条目:遍历现有 .md 文件,自问"这条描述的根本模式是否和新经验相同?"。相似 → 把新内容 merge 到已有文件(更新 错误/正确 段或追加新场景),不要建重复文件
7. 写文件。跨项目 → 在 `PENSIEVE_ROOT` 中 `git add` + `git commit`;项目特定 → 项目本身的 git 流程(不一定 commit,看项目约定)

## feedback vs pattern 定义

- **feedback**(教训):一次具体错误/correction 的记录。结构是"场景-错误-正确-后果"。例:"调价公式方向反了,把 actual+profit 当字面算"
- **pattern**(模式):跨多个具体事件观察到的结构性规律。结构是"在 X 情境下,Y 结构倾向于发生"。例:"CSV 带正负号字段 + 业务动词,字面公式常误导"
- 区别:feedback 是"出过的事",pattern 是"为什么会出过"。一次踩坑通常先记 feedback,后续观察到反复出现再抽象为 pattern

## 文件格式

```markdown
---
name: <kebab-case-slug>
description: <一句话描述>
metadata:
  node_type: memory
  type: feedback | pattern
  date: YYYY-MM-DD
  promoted: false
---

# <标题>

**场景**: ...
**错误**: ...
**正确**: ...
**后果**: ...

**参见**: <相关 memory 或 kernel,用自然语言描述关联,如"参见 002-verify-before-batch 的批量对齐规则"。不要用 [[xxx]] 这种 wiki 语法,Claude 无法解析>
```
