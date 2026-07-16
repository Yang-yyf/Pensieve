#!/bin/sh
# AI Coding OS — PostToolUse Hook
# stdin 收到 JSON: {"tool_name":"Edit","tool_input":{"file_path":"..."}, ...}
# stdout 输出 JSON，additionalContext 会被注入 Claude 上下文

set -e

# 读 stdin
input=$(cat)

# 检查 jq 是否可用
if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

tool_name=$(echo "$input" | jq -r '.tool_name // empty')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

case "$tool_name" in
  Edit|Write) ;;
  *) exit 0 ;;
esac

[ -z "$file_path" ] && exit 0

# 排除 OS 自身文件（memory/kernel/growth-log 的写入是 /learn 等技能的正常动作，不提醒）
OS_PATH_FILE="$HOME/.claude/ai-coding-os.path"
if [ -f "$OS_PATH_FILE" ]; then
  os_root=$(head -1 "$OS_PATH_FILE")
  if [ -n "$os_root" ]; then
    case "$file_path" in "$os_root"/*) exit 0 ;; esac
  fi
fi
if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  case "$file_path" in "$CLAUDE_PLUGIN_ROOT"/*) exit 0 ;; esac
fi

# 输出 JSON，additionalContext 注入 Claude 上下文（受众是 Claude，不是用户）
jq -n --arg f "$file_path" '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: ("[OS] 文件被修改: " + $f + "\n[OS] 若本次修改是在根据用户反馈纠正 AI 先前的产出，请主动向用户建议用 /learn 把这条纠正沉淀为经验。若只是正常的任务推进，忽略本提醒。")
  }
}'
