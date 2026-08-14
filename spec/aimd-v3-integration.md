# AIMD v3 集成到 bookuu/tools 体系

## 背景

定价算法 v3.0 交付包（独立 Python 脚本 + bookuu.book_price_state/t_store_price 两张表）
当前与现有 store-patrol pricing 体系完全隔离——状态表已初始化 188k 品但**输出未接通到平台改价**，
也没纳入 scheduler 监控。本 spec 把 v3 工程化进 bookuu/tools。

## 输入 / 输出

### 输入
- v3.0 交付包 Python 脚本（`状态表初始化.py` / `每日AIMD调度.py`）
- 现有 `bookuu.book_price_state` 188,194 品状态（已初始化，需迁移）
- 现有 `bookuu.t_store_price` 119,337 行历史（8-11 / 8-12 已跑过）
- PG 集群（10.90.1.22:8321，需装 plpython3u 扩展）
- 现有 store-patrol `ManualPricePipeline`（执行 manual-XXX 批次改价）

### 输出
- 新 schema `dynamic_pricing`（店铺配置 + 状态表 + 快照 + pending 表 + UDF）
- plpython3u UDF：`init_state` / `run_daily`
- scheduler Java `BookPricingAIMDTask` 调 UDF
- `t_aimd_price_pending` 表对接 store-patrol manual pipeline（source=init 走 v4 仲裁）
- 复用现有钉钉告警 + scheduler TaskExecutor 监控

## 边界

### 在做
- 新建 `dynamic_pricing` schema（店铺配置 + AIMD 状态表 + 快照 + pending + UDF）
- 把现有 `bookuu.book_price_state` / `bookuu.t_store_price` 18.8 万品状态**迁移**到新 schema
- Python 脚本逻辑改写成 plpython3u UDF（不用 psycopg2，用 SPI）
- AIMD 参数从脚本顶部硬编码 → `t_aimd_shop_config.params_json` 按店铺配
- scheduler 加 `BookPricingAIMDTask`（Java，通过 JDBC 调 `SELECT dynamic_pricing.run_daily(...)`）
- manual pipeline 改造：能从 `dynamic_pricing.t_aimd_price_pending` 拉待改价行
- AIMD 调价统一 source=init（被 marketing/lossStop/humanCommand 覆盖）

### 不做（明确排除）
- **店铺扩展到 1000238（拼多多）**：v1 仅 1000037 跑通，1000238 留 follow-up（店铺表已支持，加一行配置即可启用）
- **二期流量维度（UV/PV 加购）**：原交付包第十节"后续规划"，不做
- **1000012 主店走 AIMD**：主店是基准店，不算盈亏，不需要
- **历史 t_store_price 数据迁移**：12 万行历史调价记录保留在 bookuu schema 作归档，新 schema 从空白起步
- **参数动态调优界面**：参数靠 SQL UPDATE t_aimd_shop_config 改，不做 admin UI
- **回放/重算工具**：state_snapshot 表保留快照供事后查，但不在 v1 做回放工具

## 依赖

### 数据依赖（跨 schema 只读）
- `bookuu.t_product_shop_mapping` — 在售品映射（849 万）
- `bookuu.t_book_cost` — 成本（cost_price, rebate_cost）
- `bookuu.t_shop_product_daily_stats` — 当日动销（依赖 DataX 04:30 跑完）
- `bookuu.t_book_price_limit` — 限价
- `bookuu.t_book` — 书名

### 系统依赖
- PG 装扩展 `plpython3u`（需要 DBA superuser 权限，CREATE EXTENSION）
- Python 3 在 PG 进程内可用（PG 自带或镜像内）
- scheduler 已有 ScheduledTask 框架（接 TaskExecutor + 钉钉告警）
- store-patrol ManualPricePipeline（已有）

## 数据架构

```
dynamic_pricing schema:
├─ t_aimd_shop_config                  -- 店铺级配置（启用 AIMD 的店 + cron + 参数）
│   PK shop_code
│
├─ t_book_price_state                  -- AIMD 累积状态（从 bookuu 迁移）
│   PK (shop_code, book_id)
│
├─ t_book_price_state_snapshot         -- 每日状态快照，按日分区（回放用）
│   PARTITION BY RANGE (snapshot_date)
│
├─ t_aimd_price_pending                -- 当日调价任务（输出，对接 manual pipeline）
│   PK id (BIGSERIAL)
│   PARTITION BY RANGE (created_at)
│   字段: shop_code, book_id, target_price, reason, json_detail, source, status...
│
├─ t_store_price                       -- 调价审计（从 bookuu 迁移或新建，按日分区）
│   PARTITION BY RANGE (computed_at)
│
└─ UDF (LANGUAGE plpython3u):
    init_state(init_date DATE, shop_code TEXT)
    run_daily(stat_date DATE, shop_code TEXT)
    （内部步骤: new_book_detect / cost_change_detect / aimd_step / price_output
      作为内部函数，不对外暴露）
```

## Sub-goals

### SG1: schema + 配置表 + 状态复制
**完成判据**：schema/表/分区建好；book_price_state 188k 品**复制**到新 schema；t_aimd_shop_config 插一行 1000037。原 `bookuu.book_price_state` 表**不动**（用户手动对照用）。

- `CREATE SCHEMA dynamic_pricing`
- 建 `t_aimd_shop_config`（含 params_json 字段，存 COMMISSION/LAMBDA/K_PRICE_DOWN 等参数）
- 建 `t_book_price_state` + `t_book_price_state_snapshot`（按日分区）
- 建 `t_aimd_price_pending`（按日分区，加 reason/json_detail 字段）
- 建 `t_store_price`（按日分区）
- `INSERT INTO dynamic_pricing.t_book_price_state SELECT * FROM bookuu.book_price_state`（**只复制，不动原表**）
- `INSERT INTO dynamic_pricing.t_aimd_shop_config VALUES ('1000037', true, '0 30 9 * * ?', '{...默认参数...}')`
- plpython3u 扩展**由用户协调 DBA 安装**（见下方"DBA 需求清单"），不在 SG1 范围

### SG2: init_state UDF（plpython3u）
**完成判据**：UDF 跑通；能正确初始化 1000037（188k 品）；新店铺也能跑。

- `CREATE FUNCTION dynamic_pricing.init_state(init_date DATE, shop_code TEXT) RETURNS TEXT LANGUAGE plpython3u`
- 复用 `状态表初始化.py` 逻辑（plpython 用 `plpy.execute()` 替代 psycopg2）
- 从 `t_aimd_shop_config.params_json` 读参数（LAMBDA/PI_MIN 等）
- 跨 schema 读 `bookuu.t_product_shop_mapping` / `t_book_cost` / `t_shop_product_daily_stats`

### SG3: run_daily UDF（plpython3u，6 步骤）
**完成判据**：UDF 跑通 8-13（需先确认动销数据已同步）；输出到 t_aimd_price_pending + t_store_price。

- `CREATE FUNCTION dynamic_pricing.run_daily(stat_date DATE, shop_code TEXT) RETURNS JSONB`
- 6 步骤：新书检测 → 成本变化 → 非动销 days_idle+1 → 7天降价 → 动销品 AIMD → 定价输出
- **只写 π 变了的书**到 t_aimd_price_pending（执行才有意义，没变不写）+ t_store_price
- 每个调价品写两份：
  - `t_aimd_price_pending` 一行（shop_code, book_id, target_price=suggested_price, reason, json_detail, source='init', status='PENDING'）
  - `t_store_price` 一行（审计归档）
- reason 取值：`AIMD_UP` / `AIMD_DOWN` / `COST_SHOCK` / `LIMIT_PULL` / `LIMIT_FLOOR` / `PROMO_BUFFER`（可叠加，逗号分隔）
- json_detail 含 old_pi/new_pi/ewma/days_idle/cost_old/cost_new/shipping

### SG4: manual pipeline 对接 t_aimd_price_pending
**完成判据**：ManualPricePipeline 能识别 dynamic_pricing 的 PENDING 行，改价后回写 SUCCESS。

- store-patrol `ManualPricePipeline.runBatch()` 加一个分支：当 shop 配置了 aimd_enabled，
  占坑 SQL UNION `dynamic_pricing.t_aimd_price_pending WHERE status='PENDING' AND source='init'`
- pipeline source 字段标 `init`，走 v4 仲裁 init 优先级（被 marketing/lossStop 覆盖）
- 改价成功后回写 `dynamic_pricing.t_aimd_price_pending SET status='SUCCESS'`
- 失败回写 status='FAILED' + error_msg
- **不单独起 batch_id**：AIMD PENDING 行混进当天的 manual-XXX 批次（几万条随随便便，pipeline 已支持批量）

### SG5: scheduler BookPricingAIMDTask（Java）
**完成判据**：编译过；注册到 TaskInitializer；走 TaskExecutor 钩子（失败/超时/空跑都进钉钉告警）。

- `BookPricingAIMDTask implements ScheduledTask`
- taskCode = `BOOK_PRICING_AIMD`，cron 从 `dynamic_pricing.t_aimd_shop_config` 读
- execute(): JdbcTemplate 调 `SELECT dynamic_pricing.run_daily(CURRENT_DATE-1, shop_code)` 循环所有 aimd_enabled=true 的店
- 触发时机：`0 30 9 * * ?`（09:30，DataX 04:30 跑完后 5h 缓冲）
- **空跑保护**：调 UDF 前先查 `t_shop_product_daily_stats WHERE stat_date=CURRENT_DATE-1 COUNT(*)`，返回 0 跳过

### SG6: 文档 + 工作报告
**完成判据**：`docs/design/AIMD_v3_集成.md` + 工作报告落地。

- 设计文档（含 schema 图 / UDF 调用方式 / 参数列表 / 与现有 pricing pipeline 关系）
- `docs/ops/aimd-setup.md` 部署手册（plpython3u 安装 / 状态迁移 / 验证 UDF / manual pipeline 对接）
- 工作报告 `docs/report/YYYYMMDD/YYYYMMDD_HHmm_AIMD_v3_集成.md`

## 完成标准

- [ ] 6 个 sub-goal commit 落地
- [ ] scheduler mvn compile + 单测全过
- [ ] store-patrol mvn compile + 单测全过
- [ ] UDF 在 10.90.1.22 上能跑（验 8-13 数据）
- [ ] 钉钉收到 AIMD 失败/空跑告警（接现有钉钉告警系统）
- [ ] manual pipeline 能从 t_aimd_price_pending 拉行改价（验一两个品）
- [ ] spec 与代码一致（变更先改 spec）

## 关键技术决策

### 为什么用 plpython3u（不 Java 重写）
- 算法复杂（EWMA / 价格带 / 成本冲击），Python 已有完整实现 + 已验证 8-11/8-12 数据
- 重写 Java 风险高（300 行算法逻辑），易引入 bug
- plpython3u 进程内执行，比 Python 脚本 + psycopg2 性能更好（省 round-trip）
- 代价：需要 DBA 装 plpython3u（superuser 权限），需要 UDF 用 SPI 而非 psycopg2

### 为什么 source=init 而不是新 source=aimd
- 用户明确要求统一 init 优先级
- 现有 v4 仲裁里 init/init 互相覆盖可重跑
- marketing/lossStop/humanCommand 都能覆盖 AIMD（人为/止损优先）
- AIMD 是"基础动态调价"，不是"特殊事件"，归 init 合理

### 为什么 manual pipeline 而非新建 pipeline
- manual pipeline 已有完整改价链路（v4 仲裁 + PDD 异步 + 黑名单 + SKU 批量）
- 新建 pipeline 要重复实现这些，违反极简原则
- 改 pipeline 加 UNION 分支，5 行代码搞定

### 为什么 09:30 触发
- DataX 同步动销 04:30 跑完
- DailyLossStop 08:00 / DailyMarketing 09:00 跑完
- AIMD 09:30 跑时动销已稳定 + 早晨调价已生效，新价的反馈明天才能拿到

## 风险与缓解

| 风险 | 影响 | 缓解 |
|------|------|------|
| 动销数据 04:30 没同步完，AIMD 09:30 误判 | 高（十几万品错误降价） | scheduler 空跑保护：COUNT 当天动销 = 0 跳过 |
| plpython3u 装不上（无 superuser） | 高（阻塞 SG2/SG3） | 提前与 DBA 确认；预案：用 PL/pgSQL 重写 |
| UDF 内 Python 异常导致 PG 进程崩 | 高 | UDF 内全 try/except，异常返回 JSONB 含 error 字段，不抛 PG 异常 |
| 状态迁移丢数据 | 中 | 迁移前 COUNT 对账；保留 bookuu.book_price_state 原表 30 天再 DROP |
| manual pipeline UNION 影响原 manual 批次性能 | 中 | 加索引 + WHERE shop_code IN (aimd 启用店)；非启用店零影响 |
| 钉钉被 AIMD 失败告警刷屏 | 低 | 复用现有告警；AIMD 任务在 scheduler 内，TaskExecutor 已有去重机制（后续可加） |
| 现有 8-11/8-12 跑过的数据要重跑吗 | 低 | 不重跑；8-13 起在 dynamic_pricing 新表上跑 |

## DBA 需求清单（用户协调，不阻塞 SG1）

| # | 操作 | 权限 | 用途 | 阻塞 |
|---|------|------|------|------|
| 1 | `CREATE EXTENSION IF NOT EXISTS plpython3u` | superuser | 让 PG 能跑 Python UDF（SG2/SG3 依赖） | SG2/SG3 |
| 2 | 授权 `bookmind` 用户 `USAGE ON SCHEMA dynamic_pricing` | superuser | 让应用用户能调 UDF | SG5 |
| 3 | 授权 `bookmind` 在 dynamic_pricing schema 下 `CREATE FUNCTION` | superuser | 应用用户能 CREATE FUNCTION（如果让应用建 UDF） | SG2/SG3 |
| 4 | 确认 PG 容器/镜像里有 Python 3 解释器 | DBA | plpython3u 依赖系统 Python | SG2/SG3 |

**最小请求**（发给 DBA 的话术）：

> 在生产 PG（10.90.1.22:8321）上执行：
> ```sql
> CREATE EXTENSION IF NOT EXISTS plpython3u;
> ```
> 用 superuser 执行。执行后验证：
> ```sql
> DO $$ import sys; plpy.notice(sys.version) $$ LANGUAGE plpython3u;
> ```
> 应返回 Python 版本号。

执行完通知我，我开始 SG2/SG3 UDF。

## 关键文件清单

### 新建
- `docs/design/AIMD_v3_集成.md`
- `docs/ops/aimd-setup.md`
- `docs/sql/dynamic_pricing/` — schema + UDF SQL 文件
  - `01_schema.sql` — CREATE SCHEMA + 表 + 分区
  - `02_init_state_udf.sql` — init_state UDF
  - `03_run_daily_udf.sql` — run_daily UDF
  - `04_migrate_state.sql` — 从 bookuu 迁移状态
- `scheduler/src/main/java/org/yunzhen/scheduler/task/BookPricingAIMDTask.java`
- `store-patrol/src/main/java/org/yunzhen/storepatrol/manualprice/service/AimdPendingSync.java`（or 直接改 ManualPricePipeline）

### 改造
- `store-patrol/.../manualprice/service/ManualPricePipeline.java` — 占坑 SQL 加 UNION aimd pending
- `scheduler/.../config/TaskInitializer.java` — 注册 BOOK_PRICING_AIMD 任务
