#!/usr/bin/env python3
"""Pensieve — UserPromptSubmit Hook

每次用户发消息时,Claude Code 通过 stdin 传 JSON:
  {"user_message": "...", "session_id": "...", ...}

本脚本:
1. 解析 PENSIEVE_ROOT(从 ~/.claude/pensieve.path)
2. 遍历 principles + memory 各类目录的 .md 文件
3. 提取每个文件的关键词(标题 + description)
4. 看用户消息命中哪些关键词
5. 命中 top 3 作为 additionalContext 注入 Claude 上下文

关键词提取:
- 英文:4+ 字符的单词
- 中文:2 字符滑动窗口(bigram)
- 过滤停用词

stdout 输出 JSON:
  {"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "additionalContext": "..."}}
"""

import json
import os
import re
import sys

# 停用词(中文 + 英文)
STOPWORDS = {
    # 中文功能词
    "的", "了", "是", "在", "我", "你", "他", "她", "它", "们", "这", "那",
    "这个", "那个", "这些", "那些", "什么", "怎么", "为什么", "如何", "如果",
    "可以", "能够", "应该", "需要", "想要", "觉得", "认为", "感觉",
    "一个", "一些", "一种", "一样", "一直", "一切",
    "不要", "不得", "不能", "必须", "应当",
    "进行", "通过", "使用", "利用", "借助",
    "然后", "所以", "因为", "但是", "不过", "而且", "或者", "还是",
    "已经", "正在", "即将", "马上", "现在", "之前", "之后",
    "的话", "是的", "对的", "好的", "可以",
    # 中文 bigram 噪音(单字组合无意义)
    "我们", "你们", "他们", "这是", "那是", "就是", "还有", "没有",
    "什么", "怎么", "为何", "如何", "这样", "那样", "这一", "那一",
    # 英文 stopword
    "this", "that", "with", "from", "have", "will", "would", "could",
    "should", "their", "there", "what", "when", "where", "which", "they",
    "them", "your", "yours", "have", "has", "been", "were", "into",
    "the", "and", "for", "not", "are", "but", "all", "can", "may",
    "shall", "must", "here", "than", "then", "this", "that",
}


def extract_keywords(text):
    """提取候选关键词:英文 4+ 字符词 + 中文 2-gram。"""
    if not text:
        return set()
    kws = set()

    # 英文:4+ 字符单词
    for m in re.finditer(r"[A-Za-z][A-Za-z]{3,}", text):
        kws.add(m.group().lower())

    # 中文:2 字符滑动窗口
    chinese_chars = re.findall(r"[一-鿿]", text)
    for i in range(len(chinese_chars) - 1):
        bigram = chinese_chars[i] + chinese_chars[i + 1]
        if bigram not in STOPWORDS:
            kws.add(bigram)

    # 过滤英文停用词
    kws -= STOPWORDS
    return kws


def strip_frontmatter(content):
    """剥离 YAML frontmatter(开头两个 --- 之间),节省注入 token。"""
    if not content.startswith("---"):
        return content
    lines = content.split("\n")
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            return "\n".join(lines[i + 1:]).lstrip("\n")
    return content


def resolve_plugin_dir():
    """优先从 pointer 文件读 PENSIEVE_ROOT,失败回退到 CLAUDE_PLUGIN_ROOT。"""
    pensieve_path = os.path.expanduser("~/.claude/pensieve.path")
    if os.path.isfile(pensieve_path):
        try:
            with open(pensieve_path, encoding="utf-8") as f:
                root = f.readline().strip()
            candidate = os.path.join(root, "plugins", "pensieve")
            if os.path.isdir(candidate):
                return candidate
        except Exception:
            pass

    env_root = os.environ.get("CLAUDE_PLUGIN_ROOT", "")
    if env_root and os.path.isdir(env_root):
        return env_root

    return ""


def read_memory_metadata(filepath):
    """读 markdown 文件,提取 title + description + 正文前 500 字。"""
    try:
        with open(filepath, encoding="utf-8") as f:
            content = f.read()
    except Exception:
        return None

    title = ""
    desc = ""
    for line in content.split("\n"):
        if not title and line.startswith("# "):
            title = line[2:].strip()
        elif not desc and line.startswith("description:"):
            desc = line[len("description:"):].strip().strip("\"'")
        if title and desc:
            break

    return {
        "path": filepath,
        "title": title,
        "description": desc,
        "search_text": f"{title} {desc}",
        "preview": strip_frontmatter(content)[:500],
    }


def main():
    # 1. 读 stdin
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    user_msg = data.get("user_message", "")
    if not user_msg or len(user_msg.strip()) < 5:
        sys.exit(0)

    # 2. 定位 plugin dir
    plugin_dir = resolve_plugin_dir()
    if not plugin_dir:
        sys.exit(0)

    # 3. 搜索目录(principles + 4 类 memory)
    search_dirs = [
        os.path.join(plugin_dir, "3_kernel/principles"),
        os.path.join(plugin_dir, "2_memory/feedback"),
        os.path.join(plugin_dir, "2_memory/patterns"),
        os.path.join(plugin_dir, "2_memory/preferences"),
        os.path.join(plugin_dir, "2_memory/conventions"),
    ]

    # 加上当前项目的 raw memory(Layer 2)
    project_dir = os.environ.get("CLAUDE_PROJECT_DIR", "")
    if project_dir:
        search_dirs.extend([
            os.path.join(project_dir, ".claude/memory/feedback"),
            os.path.join(project_dir, ".claude/memory/patterns"),
            os.path.join(project_dir, ".claude/memory/preferences"),
            os.path.join(project_dir, ".claude/memory/conventions"),
        ])

    # 4. 遍历每个 memory 文件,计算匹配分
    memories = []
    for d in search_dirs:
        if not os.path.isdir(d):
            continue
        for fname in sorted(os.listdir(d)):
            if not fname.endswith(".md") or fname.startswith("EXAMPLE-"):
                continue
            meta = read_memory_metadata(os.path.join(d, fname))
            if not meta or not meta["search_text"].strip():
                continue

            keywords = extract_keywords(meta["search_text"])
            if not keywords:
                continue

            user_lower = user_msg.lower()
            matched = []
            for kw in keywords:
                if kw.lower() in user_lower:
                    matched.append(kw)

            if matched:
                # 去重 + 保留前 5 个匹配词
                seen = set()
                uniq_matched = []
                for kw in matched:
                    if kw not in seen:
                        seen.add(kw)
                        uniq_matched.append(kw)
                    if len(uniq_matched) >= 5:
                        break

                memories.append({
                    **meta,
                    "score": len(matched),
                    "matched": uniq_matched,
                })

    if not memories:
        sys.exit(0)

    # 5. 按分数排序,top 3
    memories.sort(key=lambda x: x["score"], reverse=True)
    top = memories[:3]

    # 6. 拼接 additionalContext
    parts = [
        "[Pensieve 主动召回] 你的消息命中以下相关记忆,回答时请参考(若实际无关请忽略):",
        "",
    ]
    for m in top:
        relpath = os.path.relpath(m["path"], plugin_dir)
        parts.append(f"--- {m['title']} ({relpath}, 匹配: {', '.join(m['matched'])}) ---")
        parts.append(m["preview"])
        parts.append("")

    additional_context = "\n".join(parts)

    # 7. 输出 JSON
    output = {
        "hookSpecificOutput": {
            "hookEventName": "UserPromptSubmit",
            "additionalContext": additional_context,
        }
    }
    print(json.dumps(output, ensure_ascii=False))


if __name__ == "__main__":
    main()
