---
name: pensieve-dev
description: 读 spec → 拆 sub-goals → 逐个执行（写代码+编译+测试+commit）。每个 sub-goal 一个 commit，是 spec+goal 引擎的核心。用户说 /pensieve-dev、"开干""执行""拆 sub-goals"时触发
tags: [custom, pensieve, dev, goal-engine]
---

# /pensieve-dev — 拆 sub-goals + 执行

spec+goal 引擎的核心。读 spec → 拆 N 个独立可交付的 sub-goal → 逐个走完"代码+编译+测试+commit"。

## 完成的定义（核心）

**一个 sub-goal 完成 = 代码写完 + compile 过 + 单测过 + commit 落地**。
不依赖部署、不依赖线上验证、不依赖冒烟测试。验证是另一回事，由用户单独触发 /pensieve-review。

## 前置检查

读 `{PENSIEVE_ROOT}/.state/current.json`：
- `active_phase` 必须 = `SPEC_READY`
- 否则 → 拒绝执行："spec 没准备好，先 /pensieve-spec"

读 spec 文件：
- 必须有 `## 输入 / 输出`、`## 边界`、`## 完成标准` 段
- `## Sub-goals` 段为空（或已有但需要重拆）

## 流程

### 阶段 1：SPLIT — 拆 sub-goals

读 spec 的 `## 输入 / 输出` + `## 边界` + `## 完成标准`，拆出 N 个 sub-goal。

**拆解原则**：
- **独立可交付**：每个 sub-goal 本身有业务价值，不依赖后续 sub-goal 才能跑
- **一次 commit**：粒度对齐"代码 + 测试 = 一个 commit"，不拆得太碎
- **完成判据清晰**：每个能写出"做完了 = X 状态"，不是"再调一下"
- **顺序合理**：先基础后业务，先数据后逻辑

把 sub-goals 写回 spec 文件的 `## Sub-goals` 段：

```markdown
## Sub-goals
1. <sub-goal 1 标题> — <完成判据>
2. <sub-goal 2 标题> — <完成判据>
...
```

**TaskCreate 每个 sub-goal**（用 Claude 本体的 task 工具）。

更新 current.json：
```json
{
  "active_phase": "EXEC",
  "active_subgoal": 1,
  "total_subgoals": <N>
}
```

把 spec + sub-goals 摘要给用户审一下："这样拆 OK 吗？" 用户点头进 EXEC。

### 阶段 2：EXEC — 逐 sub-goal 循环

对每个 sub-goal：

#### 步骤 a：PLAN
明确这一步改哪些文件、加哪些文件、删哪些文件。如果是改老代码，先读一遍相关文件。

#### 步骤 b：CODE
写代码 + 写测试。

#### 步骤 c：COMPILE
跑项目的编译命令：
- Maven: `mvn clean compile -DskipTests`
- npm: `npm run build` 或 `tsc --noEmit`
- Python: 启动时语法检查

失败 → 修，不进下一步。

#### 步骤 d：TEST
跑相关单测：
- 只跑和本次改动相关的测试（不要全跑，浪费时间）
- Maven: `mvn test -Dtest=XxxTest`
- npm: `npm test -- --grep "xxx"`

失败 → 修，不进下一步。

#### 步骤 e：COMMIT
commit message 格式：
```
<sub-goal N>: <sub-goal 标题>

spec: <spec 文件相对路径>
完成判据: <从 spec 复制>
```

#### 步骤 f：TaskUpdate
把当前 sub-goal 的 task 标完成。更新 current.json 的 `active_subgoal`。

### 阶段 3：WRAP

所有 sub-goal 跑完：
1. 输出总结：
   ```
   Goal: <name>
   Spec: <path>
   Sub-goals: <N>/<N> 完成
   Commits:
     - <hash> <sub-goal 1>
     - <hash> <sub-goal 2>
     ...
   ```
2. 更新 current.json：
   ```json
   {
     "active_phase": "DEV_DONE",
     "active_subgoal": <N>
   }
   ```
3. 提示用户："代码写完了，可以 /pensieve-review 走一遍"

## 失败处理

- 任一 sub-goal 的 COMPILE/TEST 失败 → 不进下一个 sub-goal，先修当前
- 修不好 → 停下来，告诉用户卡在哪
- 不要为了"跑完所有 sub-goal"而硬塞，宁可在第 3 个 sub-goal 停下来说"这里有问题"

## 关键约束

- **每步是 sub-goal**——不存在"我直接全写了"的捷径
- **每个 sub-goal 一个 commit**——不要把多个 sub-goal 塞一个 commit
- **不跳过 COMPILE/TEST**——这两步失败 = sub-goal 没完成
- **commit message 必须引用 spec**——保证 spec 和代码双向可追溯
