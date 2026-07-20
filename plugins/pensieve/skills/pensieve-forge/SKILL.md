---
name: pensieve-forge
description: 把 Pensieve 中积累的原则/偏好/约定锻造成你专属的 Claude Code skill。例:从 review 经验生成"杨逸飞的代码审查"skill,从协商经验生成"需求拆分"skill。用户说 /pensieve-forge、"锻造 skill""根据我的经验创建""生成本地 skill""定制一个"时触发
tags: [pensieve, meta, forge]
---

# /pensieve-forge — 锻造专属 skill

你不止积累经验,你还能把经验**锻造成行为**。本 skill 读取 Pensieve 的知识库,
生成一个给 Claude Code 直接使用的定制 skill。

**跟 `/pensieve-promote` 的区别**:promote 把 memory 升级为 principle(自动注入)。
forge 把知识沉淀为**可执行的 skill**(用户主动调用,带着完整的 persona + 检查清单 + 约束)。

## 触发

`/pensieve-forge <领域>` 或 `/pensieve-forge`(会问)

## 流程

### 1. 确定目标

问用户:
- skill 叫什么?(如 "杨逸飞的代码审查"、"组套选品助手")
- 干什么用?(一句话)
- **全局还是项目级?** 全局 → `~/.claude/skills/`,项目级 → `<project>/.claude/skills/`

### 2. 扫描知识源

读 PENSIEVE_ROOT 定位(读 `~/.claude/pensieve.path`):

| 来源 | 位置 | 读什么 |
|------|------|--------|
| 原则 | `PENSIEVE_ROOT/plugins/pensieve/3_kernel/principles/` | 全部(最多几十条) |
| 偏好 | `PENSIEVE_ROOT/plugins/pensieve/2_memory/preferences/` | 全部 |
| 约定 | `PENSIEVE_ROOT/plugins/pensieve/2_memory/conventions/` | 全部 |
| 教训 | `PENSIEVE_ROOT/plugins/pensieve/2_memory/feedback/` | 关键词匹配(与目标领域相关) |
| 项目 raw | `${CLAUDE_PROJECT_DIR}/.claude/memory/` | 项目特定 feedback/preferences/conventions |

若选全局 skill → 只读 Layer 1(跨项目)
若选项目级 skill → 叠加项目 raw

### 3. 筛选(自问)

对每条知识问:"这条跟 `<目标领域>` 相关吗?"

- 相关的原则 → 变成检查清单项
- 相关的偏好 → 变成角色设定(prompt 中的"你应该"指令)
- 相关的约定 → 变成硬约束(排除规则 / 默认选择)
- 相关的教训 → 变成"特别警惕"触发指令

不相关的不硬塞——生成的 skill 要精准,不是 dump。

### 4. 合成 SKILL.md

按下方模板生成,**不要照抄模板,根据实际知识内容填充**:

```markdown
---
name: <kebab-case-name>
description: <从领域的描述合成>
tags: [custom, <领域-tag>]
---

# <skill 标题>

<一句话角色定位,基于用户偏好>

## 核心能力

将相关原则逐条转化为 actionable 行为指令:
- 每条:原则标题 → 1 句具体动作("遇到 X 时,先做 Y")
- 例:001(写操作显式授权)→ "任何写操作前,确认参数已由用户显式提供"
- 例:002(批量前对齐)→ "批量处理前,先用一条样例验证结果"

## 特别警惕

基于相关教训,列出领域内的常见陷阱和触发条件:
- 每条:教训摘要 → 触发词(用户在对话中提到什么时应特别小心)
- 例:"调价公式方向陷阱" → 遇到"调价"+"补齐"+"公式",先对齐样例

## 项目约束

基于相关约定(若为项目级 skill):
- 列出必须遵守的硬约束(数据库、API、文件结构等)

## 输出要求

基于用户偏好,描述回复风格:
- <用户的偏好总结>
- 具体实例(如"输出 diff 而非描述")

## 相关知识(勿输出,仅做引用)

- 原则: <列出引用的原则编号>
- 教训: <列出引用的 feedback 文件名>
- 生成时间: <today>
```

### 5. 审阅 → 等确认

展示**完整草稿**(全部章节),问用户:
- "这是生成的 skill 草稿。哪段要改/删/加?"
- 可以调整:名称、角色定位(太激进/保守)、特定行为指令、删掉不相关的项
- 用户说"好""就这样""写" → 进入写入;说任何修改 → 改完再确认

### 6. 写入

```bash
mkdir -p <scope-path>/skills/<name>/
# 写入 SKILL.md
```

写入后提示用户:
> skill 已生成到 `~/.claude/skills/<name>/`。  
> Claude Code 自动发现用户级 skill,无需重装 plugin。  
> 试试: 在对话中说"用 `<name>` skill 审一下这段代码"

## 边界

- knowledge base 为空(没有原则/偏好) → 告诉用户"Pensieve 经验库还空着,先 /pensieve-learn 记几条经验再锻造"
- 跟目标领域完全无相关知识 → 报告"Pensieve 里目前没有与 <领域> 相关的经验,建议积累后再锻造"
- 用户选的项目级 skill 且项目无 CLAUDE.md → 提醒"项目级 skill 放在项目 .claude/skills/ 下"

## 场景示例

用户:/pensieve-forge 代码审查

Pensieve 扫到:
- 001(写操作显式授权)→ 检查清单项
- 002(批量前对齐)→ 检查清单项
- 004(只改被要求改的)→ 检查清单项
- preference:"回复简短直接"→ 角色设定: "输出格式:先结论再展开,不超过 3 段"
- feedback:"调价公式方向陷阱"→ 特别警惕: "遇到金额计算 + 业务动词,先对齐公式"
- convention:"bookuu 用 bookuu schema"→ 项目约束

→ 生成 "杨逸飞的代码审查" skill,写入 `~/.claude/skills/yyf-code-review/SKILL.md`

生成后,用户在任意项目对话中说"用 yyf-code-review 审一下这个 PR"
→ Claude 看到 skill,以杨逸飞的审查偏好执行。

## 与其他技能的关系

- `/pensieve-learn`:你先把经验记进 Pensieve(原料进入仓库)
- `/pensieve-promote`:经验反复验证后升级为原则(原料变成永久配方)
- `/pensieve-forge`:把原料 + 配方锻造成**可执行的行为**(配方变成产品)
- 生成的 skill:跟 `/feature-dev` `/request-code-review` 一样**原生 user-level skill**

这正是 Pensieve 工作伙伴的完整闭环:踩坑 → 记住 → 提炼 → **锻造成能用的东西**。
