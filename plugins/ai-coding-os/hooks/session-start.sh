#!/bin/sh
# AI Coding OS — SessionStart Hook
# SessionStart stdout 自动注入 Claude 上下文，直接 echo/cat 即可

set -e

# OS 源仓库优先（~/.claude/ai-coding-os.path 指向 Layer 1 本地仓库），
# 避免读插件安装缓存里的过期副本；无 pointer 文件时回退到缓存
PLUGIN_DIR="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
OS_PATH_FILE="$HOME/.claude/ai-coding-os.path"
if [ -f "$OS_PATH_FILE" ]; then
  os_root=$(head -1 "$OS_PATH_FILE")
  if [ -n "$os_root" ] && [ -d "$os_root/plugins/ai-coding-os" ]; then
    PLUGIN_DIR="$os_root/plugins/ai-coding-os"
  fi
fi
KERNEL_DIR="$PLUGIN_DIR/3_kernel/principles"
PATTERNS_DIR="$PLUGIN_DIR/2_memory/patterns"
LOG="$PLUGIN_DIR/growth-log.md"

today=$(date +%Y-%m-%d)
now_epoch=$(date +%s)

# 输出 markdown 文件内容,跳过开头 frontmatter(两个 --- 之间的 YAML),节省 token
strip_frontmatter() {
  awk '
    BEGIN { in_fm = 0 }
    NR==1 && /^---[[:space:]]*$/ { in_fm = 1; next }
    in_fm && /^---[[:space:]]*$/ { in_fm = 0; next }
    !in_fm { print }
  ' "$1"
}

# 日期转 epoch（macOS 兼容）
date_to_epoch() {
  date -j -f "%Y-%m-%d" "$1" "+%s" 2>/dev/null || date -d "$1" "+%s" 2>/dev/null
}

# === 框架声明：告诉 Claude 这些内容的效力 ===
echo "[AI Coding OS] 以下是用户在长期 AI 协作中沉淀的原则与模式。它们是本 session 的行为约束，不是参考资料。"
echo "[AI Coding OS] 行动前对照原则执行；若用户指令与某条原则冲突，先向用户指出冲突再继续。"

# === 加载 kernel/principles/ ===
if [ -d "$KERNEL_DIR" ]; then
  for f in "$KERNEL_DIR"/*.md; do
    [ -f "$f" ] || continue
    case "$(basename "$f")" in EXAMPLE-*) continue ;; esac
    echo ""
    echo "--- OS kernel: $(basename "$f") ---"
    strip_frontmatter "$f"
  done
fi

# === 加载 memory/patterns/ ===
if [ -d "$PATTERNS_DIR" ]; then
  for f in "$PATTERNS_DIR"/*.md; do
    [ -f "$f" ] || continue
    echo ""
    echo "--- OS pattern: $(basename "$f") ---"
    strip_frontmatter "$f"
  done
fi

# === 加载项目级 kernel（Layer 1.5）===
# 从 CLAUDE_PROJECT_DIR 向上递归找 .claude/os-project.path，加载其指向的 kernel 目录
proj_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"
while [ -n "$proj_dir" ] && [ "$proj_dir" != "/" ]; do
  marker="$proj_dir/.claude/os-project.path"
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

# === 加载项目 memory（最近 5 条 feedback，Layer 2 raw）===
PROJECT_FEEDBACK="${CLAUDE_PROJECT_DIR:-$(pwd)}/.claude/memory/feedback"
if [ -d "$PROJECT_FEEDBACK" ]; then
  count=0
  for f in $(ls -t "$PROJECT_FEEDBACK"/*.md 2>/dev/null); do
    [ -f "$f" ] || continue
    [ $count -ge 5 ] && break
    if [ $count -eq 0 ]; then
      echo ""
      echo "--- 项目 memory (recent) ---"
    fi
    echo ""
    echo "--- $(basename "$f") ---"
    head -50 "$f"
    count=$((count + 1))
  done
fi

# === 审查提醒 ===
if [ -f "$LOG" ]; then
  last_daily=$(grep 'last_daily:' "$LOG" | head -1 | sed 's/.*last_daily: *//' | tr -d ' ')
  last_weekly=$(grep 'last_weekly:' "$LOG" | head -1 | sed 's/.*last_weekly: *//' | tr -d ' ')
  last_monthly=$(grep 'last_monthly:' "$LOG" | head -1 | sed 's/.*last_monthly: *//' | tr -d ' ')

  # 日度
  if [ "$last_daily" != "$today" ] && [ -n "$last_daily" ]; then
    echo ""
    echo "[OS] 今日日度笔记未记录。今天学到什么了吗？用 /retrospect --daily 记一笔。"
  fi

  # 周度
  if [ -n "$last_weekly" ] && [ "$last_weekly" != "null" ]; then
    weekly_epoch=$(date_to_epoch "$last_weekly")
    if [ -n "$weekly_epoch" ]; then
      days_diff=$(( (now_epoch - weekly_epoch) / 86400 ))
      if [ "$days_diff" -gt 7 ]; then
        echo "[OS] 距上次周度回顾已 ${days_diff} 天，建议 /retrospect --weekly（v0.2）"
      fi
    fi
  fi

  # 月度
  if [ -n "$last_monthly" ] && [ "$last_monthly" != "null" ]; then
    monthly_epoch=$(date_to_epoch "$last_monthly")
    if [ -n "$monthly_epoch" ]; then
      days_diff=$(( (now_epoch - monthly_epoch) / 86400 ))
      if [ "$days_diff" -gt 30 ]; then
        echo "[OS] 距上次月度审查已 ${days_diff} 天，建议 /retrospect --monthly"
      fi
    fi
  fi
fi

echo ""
