#!/bin/sh
# Pensieve v2 — SessionStart Hook
# v2 简化：只注入 4 条 kernel 原则 + 项目级 kernel（Layer 1.5）
# 砍掉：memory 召回、daily/weekly/monthly 提醒（v1 的形式化玩意）
# 主动层由 user-prompt-submit.py 负责（关键词路由）

set -e

PLUGIN_DIR="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
PENSIEVE_PATH_FILE="$HOME/.claude/pensieve.path"
if [ -f "$PENSIEVE_PATH_FILE" ]; then
  pensieve_root=$(head -1 "$PENSIEVE_PATH_FILE")
  if [ -n "$pensieve_root" ] && [ -d "$pensieve_root/plugins/pensieve" ]; then
    PLUGIN_DIR="$pensieve_root/plugins/pensieve"
  fi
fi
KERNEL_DIR="$PLUGIN_DIR/3_kernel/principles"

strip_frontmatter() {
  awk '
    BEGIN { in_fm = 0 }
    NR==1 && /^---[[:space:]]*$/ { in_fm = 1; next }
    in_fm && /^---[[:space:]]*$/ { in_fm = 0; next }
    !in_fm { print }
  ' "$1"
}

echo "[Pensieve v2] 程序员 agent 已就位。4 条 kernel 原则作为硬约束生效："
echo "[Pensieve v2] 调用 playbook（explore/spec/dev/review）时若与本原则冲突，执行前提示用户。"

if [ -d "$KERNEL_DIR" ]; then
  for f in "$KERNEL_DIR"/*.md; do
    [ -f "$f" ] || continue
    case "$(basename "$f")" in EXAMPLE-*) continue ;; esac
    echo ""
    echo "--- Pensieve kernel: $(basename "$f") ---"
    strip_frontmatter "$f"
  done
fi

# 项目级 kernel（Layer 1.5）
proj_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"
while [ -n "$proj_dir" ] && [ "$proj_dir" != "/" ]; do
  marker="$proj_dir/.claude/pensieve-project.path"
  if [ -f "$marker" ]; then
    project_kernel=$(head -1 "$marker")
    if [ -n "$project_kernel" ] && [ -d "$project_kernel" ]; then
      echo ""
      echo "--- 项目级 kernel (Layer 1.5) @ $proj_dir ---"
      for f in "$project_kernel"/*.md; do
        [ -f "$f" ] || continue
        case "$(basename "$f")" in EXAMPLE-*) continue ;; esac
        echo ""
        strip_frontmatter "$f"
      done
    fi
    break
  fi
  proj_dir=$(dirname "$proj_dir")
done
