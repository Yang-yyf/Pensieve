---
name: pensieve-learn
description: 记录踩坑/经验/偏好/约定/模式。Pensieve 的工作伙伴记忆库,不止是错误档案。用户说 /pensieve-learn、或"记录一下""踩坑""教训""偏好""约定""我喜欢""这个项目"时触发
tags: [pensieve, meta, learn]
---

# /pensieve-learn — 记录到 Pensieve

Pensieve 是工作伙伴,不是只装踩坑。**四种类型**覆盖协作中所有该记的东西。

## Pensieve 源仓库定位

读 `~/.claude/pensieve.path` 第一行得到 `PENSIEVE_ROOT`(不存在则询问用户并写入)。相对路径相对于 `PENSIEVE_ROOT/plugins/pensieve/`,git 操作在 `PENSIEVE_ROOT` 中执行。绝不写插件安装缓存——那里改了不进成长曲线。

## 触发

用户说 `/pensieve-learn` 或 `/pensieve-learn <描述>`。

## 交互原则(MUST)

**每一步都要等用户确认再往下走,不跳过、不假设。**
写文件是最后一步也是唯一不可逆的一步,之前所有步骤用户都可以回退或取消。

## 执行逻辑

### 步骤 A:获取内容

用户提供了描述 → 直接用它。提供了 `/pensieve-learn` 不带描述 → 扫当前对话找候选。

- **有 2-3 个候选**:列出,等用户挑:"记哪个?或'全不记'"
- **没候选**:问"要记什么?"

### 步骤 B:整理内容 → 等确认

把描述整理成结构化草稿,**先展示给用户**:

```
**场景**: xxx
**错误/偏好/约定**: xxx  
**正确/应该**: xxx
**后果/理由**: xxx
```

问:"内容对么?要改/加/删什么,还是直接继续?"

用户说"继续"或"对"或"OK" → 进入 C。

### 步骤 C:判断类型 → 等确认

根据内容判断属于哪种,给建议:

> 看起来像 **[preference / feedback / pattern / convention]** ——(一句话理由)。  
> 四种分别是:(简短定义)
> 你觉得哪个对?

用户确认或选了别的 → 进入 D。

### 步骤 D:判断层级 → 等确认

> 这条看起来是 **[跨项目通用的 / 这个项目特定的]** ——(一句话理由)。  
> 跨项目 → `PENSIEVE_ROOT/.../2_memory/<type>/`  
> 项目特定 → `<project>/.claude/memory/<type>/`

用户确认 → 进入 E。

### 步骤 E:检查重复

扫目标目录已有文件,有相似的问:"跟 `<已有文件名>` 很像——是合并进去还是另建?" 用户决定。

### 步骤 F:确认写入 → 真正写

展示最终路径 + 文件名。

> 最后确认:要写入 `<path>` 吗?  
> (说"好/是/写"或"取消/不要")

用户确认后写入。跨项目 → `git add` + `git commit`;项目特定 → 项目本身的 git 流程。

写入后告知:"已记入 `<path>`。下次 session/Pensieve 召回时会生效。"

## memory 类型定义

**只有 feedback 是错误驱动,其他三种是工作伙伴驱动**:

- **feedback**(教训):一次具体错误/correction 的记录。结构:"场景-错误-正确-后果"。例:"调价公式方向反了,把 actual+profit 当字面算"
  - 反复出现后 promote 为 principle
- **pattern**(模式):跨事件的结构性规律。结构:"在 X 情境下,Y 倾向于发生"。例:"CSV 带正负号字段 + 业务动词,字面公式常误导"
  - SessionStart 自动注入
- **preference**(偏好):**用户的工作风格喜好**。结构:"用户偏好 X,理由 Y"。例:"回复简短直接,不堆免责声明""diff 比描述有信息量""先列改了啥再讲为什么"
  - SessionStart 自动注入,作为 always-on 工作风格
- **convention**(约定):**项目/代码的具体规矩**。结构:"在 X 中,我们用/不用 Y"。例:"bookuu 用 bookuu schema 不用 public""Java 21,需要时用 record"
  - SessionStart 自动注入(若在 Layer 1),或项目级 kernel(若项目特定)

**怎么选**:
- 出过错 → feedback
- 反复看到某结构 → pattern
- "我喜欢/我偏好/我希望 AI 总是" → preference
- "这个项目/代码的规矩是" → convention

## 文件格式

不同类型用不同模板,**统一 frontmatter**:

```markdown
---
name: <kebab-case-slug>
description: <一句话描述,关键词要准——UserPromptSubmit hook 靠这个匹配>
metadata:
  node_type: memory
  type: feedback | pattern | preference | convention
  date: YYYY-MM-DD
  promoted: false
---

# <标题>

<!-- feedback/pattern 模板 -->
**场景**: ...
**错误**: ...
**正确**: ...
**后果**: ...

<!-- preference 模板 -->
**偏好**: ...
**理由**: ...
**应用**: AI 应该怎么做

<!-- convention 模板 -->
**约定**: ...
**原因**: ...
**适用范围**: ...

**参见**: <相关 memory 或 kernel,自然语言描述关联>
```

## 重要提示

`description` 字段和标题里的关键词决定 UserPromptSubmit hook 能不能在用户提到相关话题时召回这条记忆。**关键词要具体、有辨识度**,避免"这次""那个""这件事"等无信息量词。
