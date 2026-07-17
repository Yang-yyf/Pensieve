---
name: learn
description: 从 raw 材料中提取可复用经验，写入 memory/feedback/ 或 memory/patterns/
tags: [os, meta, learn]
---

# /learn — 记录经验

## OS 源仓库定位（写入前必做）

所有写入和 git 操作都发生在 **OS 源仓库**，不是插件安装缓存（缓存里的改动不会进入成长曲线）：

1. 读 `~/.claude/ai-coding-os.path` 第一行，得到源仓库绝对路径 `OS_ROOT`
2. 若该文件不存在：询问用户其 Layer 1 仓库的本地路径，并写入该文件
3. 本技能中的相对路径（如 `2_memory/feedback/`）均相对于 `OS_ROOT/plugins/ai-coding-os/`
4. `git add` / `git commit` 在 `OS_ROOT` 中执行

## 触发

用户说 `/learn` 或 `/learn <描述>`。

## 执行逻辑

1. 如果用户提供了描述，直接处理；否则询问"要记录什么经验？"
2. 从描述中去掉项目名、时间戳、具体数据
3. 保留元结构：
   - **场景**: 在做什么的时候
   - **错误**: 发生了什么问题（或 AI 做了什么不对的事）
   - **正确**: 应该怎么做
   - **后果**: 不这样做会怎样
4. **判断目标层级**（关键）：
   - **跨项目**（方法论、协作原则、通用陷阱，换项目也成立）→ `OS_ROOT/plugins/ai-coding-os/2_memory/feedback/<slug>.md`
   - **项目特定**（某项目的端口、API 坑、配置 idiosyncrasy，换项目就无意义）→ `${CLAUDE_PROJECT_DIR}/.claude/memory/feedback/<slug>.md`
   - 判断不准时问用户："这条经验是通用的，还是只在这个项目成立？"
5. **判断类型**：
   - 一次性的教训 → `feedback/`
   - 可复用的模式草稿 → `patterns/`
6. 检查目标目录是否已有类似条目，有则合并到已有文件
7. 写文件。跨项目 → 在 `OS_ROOT` 中 `git add` + `git commit`;项目特定 → 项目本身的 git 流程（不一定 commit，看项目约定）

## 文件格式

````markdown
---
name: <kebab-case-slug>
description: <一句话描述>
metadata:
  type: feedback | pattern
  date: YYYY-MM-DD
  promoted: false
---

# <标题>

**场景**: ...
**错误**: ...
**正确**: ...
**后果**: ...

**[[引用]]**: [如果有相关 memory 或 kernel，在此列出]
````
