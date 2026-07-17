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

1. 读取指定的 memory 文件。路径支持两种：
   - Layer 1 跨项目:`2_memory/feedback/xxx.md`(相对于 `OS_ROOT/plugins/ai-coding-os/`)
   - 项目级:`.claude/memory/feedback/xxx.md`(相对于 `CLAUDE_PROJECT_DIR`)
2. 判断该 memory 是否在不同场景/项目中出现过 2 次以上：
   - 如果是(或用户明确要求 bypass)→ 继续
   - 如果不是 → 拒绝:建议积累更多验证后再升级
3. 提取可迁移命题:
   - 去掉所有具体项目名、时间、技术栈
   - 保留可迁移的判断结构
   - 每条原则 < 200 字
4. 判断目标位置:
   - 高度确信、反复验证 → `3_kernel/principles/<NNN>-<slug>.md`
   - 还未完全确信 → `3_kernel/heuristics/<slug>.md`
5. 如果进入 principles:分配下一个编号,建立对其他 kernel 文件的 `[[引用]]`
6. 写 kernel 文件(在 OS_ROOT 中)
7. **在原 memory 文件中标记 `promoted: true` + `promoted_to: 3_kernel/principles/<NNN>-<slug>.md`** —— 不管源在 Layer 1 还是项目级,都要回填
8. 在 OS_ROOT 中 `git add` + `git commit -m "promote: <memory> → principle #N"`
   (若源在项目级,项目仓库自己也应 commit 一次标记变更)

## Bootstrapping 例外

首批 kernel 允许 bypass"2 次验证"规则——系统第一条原则天然无法自举。
用户在初始化时手动确认即可。
