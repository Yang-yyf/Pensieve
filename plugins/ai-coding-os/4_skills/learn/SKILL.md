---
name: learn
description: 从 raw 材料中提取可复用经验，写入 memory/feedback/ 或 memory/patterns/
tags: [os, meta, learn]
---

# /learn — 记录经验

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
4. 判断类型：
   - 一次性的教训 → `2_memory/feedback/<slug>.md`
   - 可复用的模式草稿 → `2_memory/patterns/<slug>.md`
5. 检查 memory/ 是否已有类似条目，有则合并到已有文件
6. 写文件，执行 `git add` + `git commit -m "learn: <summary>"`

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
