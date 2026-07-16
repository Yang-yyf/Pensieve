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

# 输出 JSON，additionalContext 会被注入上下文
jq -n --arg f "$file_path" '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: ("[OS] 文件被修改: " + $f + "\n[OS] 如果这是对 AI 产出的纠正，输入 /learn 记录。")
  }
}'
