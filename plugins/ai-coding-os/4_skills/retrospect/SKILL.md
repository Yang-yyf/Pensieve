---
name: retrospect
description: 定期审查 kernel + memory，清理、合并、废弃过时条目
tags: [os, meta, retrospect]
---

# /retrospect — 审查

## OS 源仓库定位（执行前必做）

读 `~/.claude/ai-coding-os.path` 第一行得到源仓库路径 `OS_ROOT`（不存在则询问用户并写入）。
本技能中的路径（`3_kernel/`、`2_memory/`、`growth-log.md`）均相对于
`OS_ROOT/plugins/ai-coding-os/`，git 操作在 `OS_ROOT` 中执行。禁止写插件安装缓存。

## 触发

- `/retrospect --daily` — 日度笔记（30 秒）
- `/retrospect --monthly` — 月度审查（20 分钟）
- v0.2: `/retrospect --weekly`

## --daily

1. 询问:"今天学到了什么?(一句话即可)"
2. 在 `growth-log.md` 的"日度笔记"表格(`| 日期 | 笔记 |`)追加一行,日期为今天,笔记为用户回答
3. 把 frontmatter 的 `last_daily: YYYY-MM-DD` 改为今天

## --monthly

1. 列出所有 `3_kernel/principles/` 文件,按 last-modified 排序
2. 逐条询问用户该原则是否近期被触发(人工判断)
3. 标注超过 3 个月未触发的原则 → 建议评估
4. 列出 promote 候选,扫描两个来源:
   - Layer 1 `2_memory/feedback/`(跨项目)
   - 当前项目 `${CLAUDE_PROJECT_DIR}/.claude/memory/feedback/`(项目级)
   - 跳过已标记 `promoted: true` 的条目
5. 列出可能重复或矛盾的条目 → 建议合并
6. 列出 `3_kernel/heuristics/` → 升级/保持/废弃
7. 用户逐条确认后执行
8. 在 `growth-log.md` 的"月度审查"表格(`| 日期 | 清理 | 升级 | 废弃 |`)追加一行,日期为今天,清理/升级/废弃填本次相应数量;并把 frontmatter 的 `last_monthly: YYYY-MM-DD` 改为今天
9. `git commit -m "retrospect: YYYY-MM-DD (monthly)"`
