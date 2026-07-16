#!/bin/sh
# AI Coding OS — SessionStart Hook
# SessionStart stdout 自动注入 Claude 上下文，直接 echo/cat 即可

set -e

PLUGIN_DIR="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
KERNEL_DIR="$PLUGIN_DIR/3_kernel/principles"
PATTERNS_DIR="$PLUGIN_DIR/2_memory/patterns"
LOG="$PLUGIN_DIR/growth-log.md"

today=$(date +%Y-%m-%d)
now_epoch=$(date +%s)

# 日期转 epoch（macOS 兼容）
date_to_epoch() {
  date -j -f "%Y-%m-%d" "$1" "+%s" 2>/dev/null || date -d "$1" "+%s" 2>/dev/null
}

# === 加载 kernel/principles/ ===
if [ -d "$KERNEL_DIR" ]; then
  for f in "$KERNEL_DIR"/*.md; do
    [ -f "$f" ] || continue
    case "$(basename "$f")" in EXAMPLE-*) continue ;; esac
    echo ""
    echo "--- OS kernel: $(basename "$f") ---"
    cat "$f"
  done
fi

# === 加载 memory/patterns/ ===
if [ -d "$PATTERNS_DIR" ]; then
  for f in "$PATTERNS_DIR"/*.md; do
    [ -f "$f" ] || continue
    echo ""
    echo "--- OS pattern: $(basename "$f") ---"
    cat "$f"
  done
fi

# === 加载项目 memory（最近 5 条 feedback）===
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
