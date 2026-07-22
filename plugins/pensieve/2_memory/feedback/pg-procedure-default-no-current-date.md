---
name: pg-procedure-default-no-current-date
description: PG PROCEDURE 参数 DEFAULT 不能用 CURRENT_DATE / NOW() 等 STABLE/VOLATILE 函数——会直接报"cannot use date/time expressions in DEFAULT expression"；用 DEFAULT NULL + body 里 IF NULL THEN 赋值替代
metadata:
  node_type: memory
  type: feedback
  date: 2026-07-22
  promoted: false
---

# PG PROCEDURE 参数 DEFAULT 不能用 CURRENT_DATE

**场景**: 给 PG PROCEDURE 参数设默认值，想让"未传时默认到今天-45 天"。

**错误**:
```sql
CREATE PROCEDURE run_tier_label(
    p_stat_date DATE DEFAULT (CURRENT_DATE - 45)
)
```
PG 直接报 `ERROR: cannot use CURRENT_DATE in DEFAULT expression` / `cannot use date/time expressions in DEFAULT expression`。PROCEDURE 建不起来。

**正确**:
```sql
CREATE PROCEDURE run_tier_label(
    p_stat_date DATE DEFAULT NULL
)
LANGUAGE plpgsql AS $$
BEGIN
    IF p_stat_date IS NULL THEN
        p_stat_date := CURRENT_DATE - 45;
    END IF;
    ...
END $$;
```
PG 不允许 STABLE/VOLATILE 函数（CURRENT_DATE / NOW / CURRENT_TIMESTAMP 等）做参数 DEFAULT，函数 body 内可以正常用。

**后果**: 如果没在本地 `psql -f` 跑过就上线，PROCEDURE 创建失败导致整个迁移脚本失败回滚。

**参见**: `/Users/admin/Downloads/book-pricing/UDF-v2/02_run_tier_label.sql`
