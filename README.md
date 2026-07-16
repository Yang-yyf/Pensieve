# AI Coding OS

**AI Coding OS** 是一个 Claude Code plugin，帮你把跟 AI 协作中的经验、原则、决策
从"脑子里"搬到"git 仓库里"。

## 核心理念

- **代码是 AI 吐出来的，文件夹里放的是决策**
- **旧项目结构 = 空间维度（src/test/docs）；新项目结构 = 时间维度（raw → memory → kernel）**
- **Git log = 认知成长曲线；git blame = 每条原则的病史**

## 三层架构

```
Layer 0: 开源模板（本 repo）          ← marketplace，你从这 fork
    ↓ fork
Layer 1: 你的成长版（private fork）   ← 你的原则、记忆、分身
    ↓ /plugin install
Layer 2: 实际项目                    ← 引用你的 plugin
```

## 快速开始

### 1. Fork 本仓库到你的 GitHub

### 2. 注册你的 fork 为 marketplace

在你的项目目录启动 Claude Code，然后：

```
/plugin marketplace add https://github.com/<你的用户名>/ai-coding-os
/plugin install ai-coding-os@ai-coding-os
```

### 3. 登记源仓库路径

`/learn` `/promote` 的写入要进你的 fork（源仓库），不是插件缓存：

```bash
echo "<你的 fork 本地路径>" > ~/.claude/ai-coding-os.path
```

### 4. 你的第一条原则

删除 EXAMPLE 文件：

```bash
cd <你的 fork 路径>
rm plugins/ai-coding-os/3_kernel/principles/EXAMPLE-principle.md
rm plugins/ai-coding-os/3_kernel/decisions/EXAMPLE-decision.md
```

用 `/learn` 记录你的第一条经验，然后用 `/promote` 把它升级为原则。

## 目录结构

```
plugins/ai-coding-os/
├── hooks/               ← SessionStart + PostToolUse
├── 2_memory/            ← 你的经验
├── 3_kernel/            ← 提炼后的原则
├── 4_skills/            ← /learn /promote /retrospect
├── agents/              ← 你训练的 AI 分身
└── growth-log.md        ← 进化日记
```

## License

MIT
