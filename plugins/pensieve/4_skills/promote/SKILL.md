---
name: promote
description: 把已积累的 memory 升级为 kernel 原则或试探规则。用户说 /promote 或"升级为原则""通用化""这条经验可迁移"时触发
tags: [os, meta, promote]
---

# /promote — 飞跃

## Pensieve 源仓库定位

读 `~/.claude/pensieve.path` 第一行得到 `PENSIEVE_ROOT`(不存在则询问用户并写入)。相对路径相对于 `PENSIEVE_ROOT/plugins/pensieve/`,git 操作在 `PENSIEVE_ROOT` 中执行。绝不写插件安装缓存。

## principles vs heuristics 定义

- **principle**(原则):跨所有项目成立的硬约束。违反会造成真实损害。例:"写操作必须用户显式授权"。每次只能少几条,值得占 SessionStart token
- **heuristic**(试探规则):经验法则,通常对但有例外。例:"优先 Alpine 而非 Ubuntu 基础镜像"。可多可少,作参考
- 区别:principle 是"必须",heuristic 是"建议"。不确定时先放 heuristics,等再积累证据再升级 principle

## 触发

用户说 `/promote <memory-path>`。

## 执行逻辑

1. 读取指定的 memory 文件。路径支持两种:
   - Layer 1 跨项目:`2_memory/feedback/xxx.md`(相对于 `PENSIEVE_ROOT/plugins/pensieve/`)
   - 项目级:`.claude/memory/feedback/xxx.md`(相对于 `CLAUDE_PROJECT_DIR`)
2. **判断该 memory 是否在 2 个以上场景/项目出现过**(关键门槛):
   - 方法:遍历两个目录的每个 .md 文件:
     - `PENSIEVE_ROOT/plugins/pensieve/2_memory/feedback/`
     - `${CLAUDE_PROJECT_DIR}/.claude/memory/feedback/`
   - 对每个文件,读 标题 + 错误/正确 段,自问:"这条描述的根本模式(不是表面场景)是否和正在 promote 的 memory 相同?"
   - 计数相似条目(含当前条目)
   - 2+ 次 → 继续;1 次 → 拒绝,告知"目前只观察到 1 次出现,建议积累更多验证后再升级";用户明确 bypass → 继续
3. 提取可迁移命题:
   - 去掉所有具体项目名、时间、技术栈
   - 去掉项目风味用词(如"线上""博库""店铺"换成更通用的"生产""对外""系统")
   - 保留可迁移的判断结构
   - 每条原则正文 < 200 字
4. 判断目标位置:
   - 高度确信、反复验证 → `3_kernel/principles/<NNN>-<slug>.md`
   - 还未完全确信 → `3_kernel/heuristics/<slug>.md`
5. 进入 principles 时分配编号:扫描 `3_kernel/principles/[0-9]*-*.md` 找最大编号 N,新原则用 N+1(三位补零,如 `005-xxx.md`)
6. 写 kernel 文件(在 PENSIEVE_ROOT 中),按下方模板。**填 参见 字段前**:扫所有已有原则的标题和 规则 段,自问"新原则和哪条共享触发条件或后果?",列相关原则。无相关则填"无",不要硬凑
7. **回填原 memory 文件的 promoted 标记**(关键,/retrospect 据此跳过):
   - 位置:**frontmatter metadata 块内**(文件开头两个 `---` 之间),不是正文
   - 添加两个字段:
     ```
     metadata:
       ...(已有字段)
       promoted: true
       promoted_to: 3_kernel/principles/<NNN>-<slug>.md
     ```
   - 若原 memory 文件没有 frontmatter,先补一个再回填
8. 在 PENSIEVE_ROOT 中 `git add` + `git commit -m "promote: <memory> → principle <NNN>-<slug>"`(NNN 与文件名一致,如 "→ principle 005-avoid-night-batch")
   (若源在项目级,项目仓库自己也应 commit 一次标记变更)

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
