---
name: promote
description: 将已验证的 memory 飞跃为 kernel 原则或试探规则
tags: [os, meta, promote]
---

# /promote — 飞跃

## OS 源仓库定位（写入前必做）

读 `~/.claude/ai-coding-os.path` 第一行得到源仓库路径 `OS_ROOT`（不存在则询问用户并写入）。
本技能中的路径均相对于 `OS_ROOT/plugins/ai-coding-os/`，git 操作在 `OS_ROOT` 中执行。
禁止写插件安装缓存。

## 触发

用户说 `/promote <memory-path>`。

## 执行逻辑

1. 读取指定的 memory 文件。路径支持两种:
   - Layer 1 跨项目:`2_memory/feedback/xxx.md`(相对于 `OS_ROOT/plugins/ai-coding-os/`)
   - 项目级:`.claude/memory/feedback/xxx.md`(相对于 `CLAUDE_PROJECT_DIR`)
2. **判断该 memory 是否在 2 个以上场景/项目出现过**(关键门槛):
   - 方法:扫描两个目录的所有 .md 文件,找语义相似的条目(主题相同、错误模式相同、教训结构可对应)
     - `OS_ROOT/plugins/ai-coding-os/2_memory/feedback/`
     - `${CLAUDE_PROJECT_DIR}/.claude/memory/feedback/`
   - 找到 2+ 次相似(含当前条目) → 继续
   - 找不到 → 拒绝,告知用户"目前只观察到 1 次出现,建议积累更多验证后再升级"
   - 用户明确要求 bypass → 继续(bootstrapping 模式)
3. 提取可迁移命题:
   - 去掉所有具体项目名、时间、技术栈
   - 保留可迁移的判断结构
   - 每条原则正文 < 200 字
4. 判断目标位置:
   - 高度确信、反复验证 → `3_kernel/principles/<NNN>-<slug>.md`
   - 还未完全确信 → `3_kernel/heuristics/<slug>.md`
5. 进入 principles 时分配编号:扫描 `3_kernel/principles/[0-9]*-*.md` 找最大编号 N,新原则用 N+1(三位补零,如 `005-xxx.md`)
6. 写 kernel 文件(在 OS_ROOT 中),按下方模板
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
8. 在 OS_ROOT 中 `git add` + `git commit -m "promote: <memory> → principle #N"`
   (若源在项目级,项目仓库自己也应 commit 一次标记变更)

## 原则文件模板

```markdown
---
name: <kebab-case-slug>
description: <一句话描述,便于检索>
metadata:
  type: principle
  status: active
  since: YYYY-MM-DD
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
