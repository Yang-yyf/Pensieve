---
name: learn
description: 记录踩坑/经验/偏好/约定/模式。Pensieve 的工作伙伴记忆库,不止是错误档案。用户说 /pensieve:learn、或"记录一下""踩坑""教训""偏好""约定""我喜欢""这个项目"时触发
tags: [pensieve, meta, learn]
---

# /pensieve:learn — 记录到 Pensieve

Pensieve 是工作伙伴,不是只装踩坑。**四种类型**覆盖协作中所有该记的东西。

## Pensieve 源仓库定位

读 `~/.claude/pensieve.path` 第一行得到 `PENSIEVE_ROOT`(不存在则询问用户并写入)。相对路径相对于 `PENSIEVE_ROOT/plugins/pensieve/`,git 操作在 `PENSIEVE_ROOT` 中执行。绝不写插件安装缓存——那里改了不进成长曲线。

## 触发

用户说 `/pensieve:learn` 或 `/pensieve:learn <描述>`。

## 执行逻辑

1. 如果用户提供了描述,直接处理。
   否则**先扫当前 session 最近的对话**,看是否有可提炼的内容(用户刚纠正过 AI、刚表达过偏好、刚提到某个项目约定、刚复盘某个判断等)。
   - 有候选 → 列出来让用户挑:"看起来这几处可能是值得记的,记哪个?"(给出 2-3 个候选,每个一句话)
   - 没候选 → 问"要记什么?"
2. 从描述中去掉时间戳、具体数据。**保留项目名**(若 convention/preference 是项目特定的)
3. **判断类型**(参见下方"memory 类型定义"):
   - feedback → `feedback/`
   - pattern → `patterns/`
   - preference → `preferences/`
   - convention → `conventions/`
4. **判断目标层级**:
   - **跨项目**(方法论、协作原则、通用偏好如"回复风格")→ `PENSIEVE_ROOT/plugins/pensieve/2_memory/<type>/<slug>.md`
   - **项目特定**(某项目端口、API 坑、项目代码约定)→ `${CLAUDE_PROJECT_DIR}/.claude/memory/<type>/<slug>.md`
   - 判断不准时问用户:"这条是通用的,还是只在这个项目成立?"
5. 检查目标目录是否已有类似条目:遍历现有 .md 文件,自问"这条描述的根本模式是否和新内容相同?"。相似 → merge 到已有文件,不要建重复
6. 写文件。跨项目 → `PENSIEVE_ROOT` 中 `git add` + `git commit`;项目特定 → 项目本身的 git 流程

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
