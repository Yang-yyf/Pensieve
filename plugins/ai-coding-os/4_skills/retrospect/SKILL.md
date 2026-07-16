---
name: retrospect
description: 定期审查 kernel + memory，清理、合并、废弃过时条目
tags: [os, meta, retrospect]
---

# /retrospect — 审查

## 触发

- `/retrospect --daily` — 日度笔记（30 秒）
- `/retrospect --monthly` — 月度审查（20 分钟）
- v0.2: `/retrospect --weekly`

## --daily

1. 询问："今天学到了什么？（一句话即可）"
2. 在 `growth-log.md` 日度笔记表格追加一行
3. 更新 frontmatter 的 `last_daily` 时间戳

## --monthly

1. 列出所有 `3_kernel/principles/` 文件，按 last-modified 排序
2. 逐条询问用户该原则是否近期被触发（人工判断）
3. 标注超过 3 个月未触发的原则 → 建议评估
4. 列出 `2_memory/` 中已验证多次的条目 → 建议 /promote
5. 列出可能重复或矛盾的条目 → 建议合并
6. 列出 `3_kernel/heuristics/` → 升级/保持/废弃
7. 用户逐条确认后执行
8. 更新 `growth-log.md` 月度审查表格 + `last_monthly` 时间戳
9. `git commit -m "retrospect: YYYY-MM-DD (monthly)"`
