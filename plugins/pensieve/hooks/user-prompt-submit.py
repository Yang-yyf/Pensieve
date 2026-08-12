#!/usr/bin/env python3
"""Pensieve v2 — UserPromptSubmit Hook

轻量关键词路由提醒。每次用户提交 prompt：
  1. 扫描关键词判断场景（改老功能 / 新需求 / 完成 PR / 其他）
  2. 命中场景 → 输出单行提醒，建议对应 playbook
  3. 不命 → 静默

不强介入、不注入大段上下文。Pensieve 是副驾不是讲师。

stdout 输出 JSON:
  {"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "additionalContext": "<单行提醒>"}}

输入 JSON 字段（Claude Code 通过 stdin 传）:
  {"user_message": "...", "session_id": "...", ...}
"""

import json
import os
import re
import sys


# 关键词分组（中文 + 英文）
KEYWORDS = {
    "explore": {
        "trigger": [
            "改", "修", "重构", "迁移", "替换", "改造", "重写",
            "refactor", "rewrite", "migrate",
        ],
        "context": [
            "现有", "已经", "目前", "原来的", "老的", "之前",
            "现有功能", "老功能", "老代码",
            "existing", "current", "old",
        ],
        "hint": "这看起来是改老功能，要不要先 /pensieve-explore 调研+走读代码？",
    },
    "spec": {
        "trigger": [
            "实现", "做", "加", "新增", "开发", "搞一个", "来一个",
            "implement", "build", "add", "create",
        ],
        "context": [
            "新", "新的", "全新", "之前没有", "从来没有",
            "new feature", "from scratch",
        ],
        "hint": "这看起来是新需求，要不要先 /pensieve-spec 写需求 spec？",
    },
    "review": {
        "trigger": [
            "完成", "PR", "merge", "提交了", "改完了", "做完了", "好了",
            "review", "审查", "看一下", "审一下",
        ],
        "context": [
            "PR", "merge", "提交", "完了", "好了",
            "review", "审查",
        ],
        "hint": "这看起来是完成阶段，要不要 /pensieve-review 走一遍 diff？",
    },
}


def classify_intent(message):
    """返回 (intent_key, hint) 或 (None, None)。"""
    msg_lower = message.lower()

    for intent, cfg in KEYWORDS.items():
        triggered = any(kw in message or kw.lower() in msg_lower for kw in cfg["trigger"])
        if not triggered:
            continue

        context_required = intent in ("explore", "spec")
        if context_required:
            ctx_hit = any(kw in message or kw.lower() in msg_lower for kw in cfg["context"])
            if not ctx_hit:
                continue

        return intent, cfg["hint"]

    return None, None


def should_skip(message):
    """短消息 / 单词命令 / 纯文件路径，跳过。"""
    s = message.strip()
    if len(s) < 8:
        return True
    if re.match(r"^/pensieve", s):
        return True
    if re.match(r"^[\w./\-]+\.\w+$", s):
        return True
    return False


def main():
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        sys.exit(0)

    user_msg = data.get("user_message", "")
    if not user_msg or should_skip(user_msg):
        sys.exit(0)

    intent, hint = classify_intent(user_msg)
    if not intent:
        sys.exit(0)

    output = {
        "hookSpecificOutput": {
            "hookEventName": "UserPromptSubmit",
            "additionalContext": f"[Pensieve] {hint}",
        }
    }
    print(json.dumps(output, ensure_ascii=False))


if __name__ == "__main__":
    main()
