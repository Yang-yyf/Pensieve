# 钉钉告警 + 利润日报

## 背景

数据同步任务失败、线上定时任务失败，运营**完全不知道**——只能事后翻日志。
前一天店铺利润情况也无日常触达通道。
新增钉钉机器人作为统一通知出口：失败实时推 + 每天 10:00 利润日报。

## 输入 / 输出

- **输入**：
  - 任务失败信号：`bookuu.t_task_execution_log` 写入 FAILED/TIMEOUT 行（scheduler 内部直接钩子）
  - 利润数据：`bookuu.t_shop_product_daily_stats`（stat_date=CURRENT_DATE-1，shop_code IN 1000037/1000238）
  - 钉钉机器人：webhook URL + secret（application.yml 配置）
- **输出**：
  - scheduler 服务内：`DingTalkClient`（HTTP + 签名）+ `TaskFailureAlertHook`（钩子）+ `DailyProfitReportTask`（日报）
  - 配置：`application.yml` 加 `dingtalk.webhook / dingtalk.secret`
  - 任务定义：`DAILY_PROFIT_REPORT` 注册到 `t_task_definition`，cron `0 0 10 * * ?`

## 边界

### 在做
- **scheduler 服务的任务失败实时告警**（覆盖所有 ScheduledTask + DATAX_JOB_*）
- **每日 10:00 利润日报**（1000037 + 1000238）
- 钉钉 markdown 消息（日报用 markdown 表格，告警用 text 突出错误）
- 钉钉加签认证（HMAC-SHA256，secret 来自配置）

### 不做（明确排除）
- **store-patrol 批量任务失败告警**：跨服务，需在 store-patrol 复制一份 DingTalkClient。先做 scheduler 部分（80% 价值），store-patrol 留 follow-up
- **告警去重 / 限流**：v1 每次失败都推，连续失败会刷屏。后续可加"同 taskCode 5min 内只推一次"
- **告警级别分级**（warning/critical）：v1 全部按错误推
- **回执 / 确认机制**：单向通知，不需要确认已读
- **日报历史归档**：不发 PG 落库，钉钉群本身就是归档
- **多群分流**：v1 单群，所有消息进同一个机器人

## 依赖

- `bookuu.t_task_execution_log` — scheduler 内部表，TaskExecutor 已写
- `bookuu.t_shop_product_daily_stats` — DataX 每天凌晨从 Oracle `tj_date_shop_dp` 同步
- scheduler 的 ScheduledTask / TaskExecutor / TaskInitializer 框架（已存在）
- 钉钉机器人自定义 webhook（outbound HTTP，签名用 javax.crypto）

## Sub-goals

### SG1: DingTalkClient 基础设施
**完成判据**：单测过（验签名算法对 + HTTP payload 格式对，mock RestTemplate），mvn compile 过。

- 新建 `scheduler/.../alert/DingTalkClient.java`
- 配置通过 `@Value("${dingtalk.webhook:}")` / `@Value("${dingtalk.secret:}")` 直接注入 DingTalkClient 构造器（不单独抽 DingTalkProperties 类）
- `application.yml` 加配置占位（dev 用空，prod 用真实 webhook+secret）
- 签名算法：`String sign = HmacSHA256(timestamp + "\n" + secret, secret)`，base64 编码，URL append `&timestamp=...&sign=...`
- 消息格式：markdown 类型，title + text
- HTTP 失败不抛异常（log.warn 后吞掉，告警不能阻塞主流程）

### SG2: TaskExecutor 失败钩子
**完成判据**：编译过 + 故意触发一个任务失败，钉钉收到推送。

- 在 `TaskExecutor.execute()` 的 finally 块加钩子
- 调 DingTalkClient.sendAlert("⚠️ 任务失败: " + taskName + "\n错误: " + message + "\n时间: " + now)
- 钩子内部 try-catch 兜底（告警失败不能影响 task 状态写入）
- **不**改 RUNNING / SUCCESS 分支

### SG3: 每日利润日报任务
**完成判据**：编译过 + 单测过（mock JdbcTemplate 返回 fixture 数据，验 markdown 渲染对）+ 注册到 t_task_definition。

- 新建 `scheduler/.../task/DailyProfitReportTask.java` implements ScheduledTask
- taskCode = `DAILY_PROFIT_REPORT`，cron = `0 0 10 * * ?`
- 查昨日 1000037 + 1000238 的 SUM(quantity/actual/cost/profit)
- 计算毛利率（不做前 7 天环比，v1 排除）
- TOP 5 亏损品（净利润 ASC）
- SQL 加 `AND book_id !~ '^[AZ]'` 过滤组套/赠品/内部测试品（对齐 PricingQueryService 口径）
- markdown 表格推钉钉
- 在 `TaskInitializer` 注册

### SG4: 端到端联调脚本 + 收尾
**完成判据**：admin 接口能手动触发测试告警 + 测试日报，commit 落地。

- 加一个 admin REST 端点：`POST /api/v1/admin/alert/test`（发测试消息验通）
- 加一个 admin REST 端点：`POST /api/v1/admin/alert/profit-test`（手动触发日报，验数据）
- 配置文档：`docs/ops/dingtalk-setup.md`（机器人创建步骤 + secret 配置位置）

## 完成标准

- [ ] 4 个 sub-goal commit 落地
- [ ] scheduler mvn compile -DskipTests -s maven-settings.xml 全过
- [ ] 单测覆盖：DingTalkClient 签名算法 + DailyProfitReportTask markdown 渲染
- [ ] spec 与代码一致（变更先改 spec）

## 关键技术决策

### 为什么实时用钩子而非扫描
扫描（5min/次 t_task_execution_log）简单但延迟最大 5min。
钩子在 TaskExecutor finally 块调用，0 延迟。代价是改框架代码（但只加 5 行 try-catch 调用）。

### 为什么 scheduler 单服务先做
跨服务共享 DingTalkClient 需要抽 common module（成本高）。
scheduler 已经覆盖 80% 价值（DataX + 业务任务）。store-patrol 的批量任务失败相对低频，留 follow-up。

### 钉钉加签 vs 关键字
钉钉机器人 3 种安全设置：自定义关键词、加签、IP 白名单。
加签最安全（防 token 泄露后被滥用），用 javax.crypto HmacSHA256 实现。

## 风险与缓解

| 风险 | 影响 | 缓解 |
|------|------|------|
| 钉钉被刷屏（任务循环失败） | 高 | v1 不去重，靠 task timeout 兜底；SG2 后观察 1 周再加去重 |
| 钉钉 API 限流（1 个机器人 20 条/min） | 中 | 单服务低频，远低于限流；日报 1 条/天，告警 < 10 条/天 |
| 配置错（webhook/secret 写错） | 中 | 启动时发一条 "scheduler 上线通知" 到钉钉，肉眼验通 |
| 凭证进 git | 高 | application.yml 只放占位/空值，prod 真实值走 docker-compose env 注入 |
| TaskExecutor 钩子异常影响任务 | 高 | 钩子内部全 try-catch，告警失败只 log.warn，不抛 |
