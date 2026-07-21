---
name: use-project-schema
description: 数据库查询默认用项目 schema,不用 public
metadata:
  node_type: memory
  type: convention
  date: 2026-07-21
  promoted: false
---

# 数据库 schema 约定

**约定**: 所有 SQL 查询默认用项目专属 schema(如 `bookuu.`),不写裸表名。

**原因**: 裸表名走 public schema,可能命中错误的表或权限不足。

**适用范围**: 本项目所有 SQL(手写、DataX、脚本)。

**参见**: 无

---

> ⚠️ 这是示例文件。fork 后请删除,替换为你自己的约定。
