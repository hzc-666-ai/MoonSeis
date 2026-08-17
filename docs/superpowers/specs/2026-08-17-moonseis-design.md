# MoonSeis 设计文档

- 日期：2026-08-17
- 状态：已确认（用户已批准整体设计）
- 模块名：`<占位，待用户提供>`（当前暂用 `Noverberrain/moonseis`，发布前需替换）
- 仓库：`<待用户提供 GitHub 链接>`
- 范围：阶段 1-4（骨架、miniSEED 3 解析、波形重建、质量检测、STA/LTA 事件检测）

## 1. 项目定位

MoonSeis 是一个纯 MoonBit 实现的地震波形数据解析、质量检测与震相事件识别工具包。

核心能力：miniSEED 3 二进制记录解析 → FDSN 数据源识别 → 连续波形重建 → 缺口/重叠/异常检测 → 波形预处理 → STA/LTA 事件触发 → JSON/CSV/GeoCSV/终端报告输出。

本项目不做地震预测，不做大型科学计算平台，不与通用 DSP 库（如 moondsp）竞争，重点是地震行业数据标准、波形记录拼接、质量控制与事件检测。可作为 MoonBit 库使用，也可作为命令行工具运行。

明确不做（后续加分项，仅预留接口）：Steim-1/2 解压、miniSEED 2.4 兼容读取、Wasm 波形查看器、SARIF 完整适配。

## 2. 工程与模块

- 位置：`E:\javacode\moonbit黑客松\moonseis`
- `moon.mod`（新格式）：
  - `name`：`<占位>`，当前 `Noverberrain/moonseis`
  - `preferred_target`：`native`（CLI 为主要交付物；后续 Wasm 查看器单独编译）
  - license、readme、description、keywords 齐全
- 沿用兄弟项目（moonsatkit 等）的工程约定与风格。

## 3. 子包结构

每个子目录一个 moon.pkg（公共 API 用 `pub`，跨包可见）：

```
moonseis/
├── sid/          # FDSN Source Identifier
├── time/         # 高精度时间
├── binary/       # 有界二进制读取器
├── miniseed3/    # miniSEED 3 固定头与校验
├── encoding/     # 样本解码
├── record/       # Record 领域模型
├── trace/        # 连续波形重建
├── quality/      # 质量检查规则
├── signal/       # 波形预处理
├── trigger/      # STA/LTA 事件检测
├── formats/      # JSON/CSV/GeoCSV/Markdown/文本/SARIF(预留)
├── cmd/main/     # CLI
├── examples/
├── fixtures/     # 合成 + 真实(可选) 样本
├── docs/
└── tests/        # 跨包集成测试
```

## 4. 核心类型

### 4.1 sid.SourceIdentifier

- 格式：`FDSN:NET_STA_LOC_BAND_SRC_SUB`，下划线(ASCII 95)分隔
- 缩略形式：`FDSN:NET_STA_LOC` / `FDSN:NET_STA` / `FDSN:NET`
- 必填：network、station、source；可选：location、band、subsource
- 字符集：`[A-Z0-9]`；station、location 额外允许 `-`(ASCII 45)
- 长度：network 1-8、station 1-8、location ≤8；band/source/subsource 单字符为主（通道映射规则以 SEED 2.4 NSLC 兼容为准）
- 禁止：location 为 `--`（两个连字符）
- 前缀 `FDSN:` 为保留命名空间标识

API：
```moonbit
let sid = @sid.parse("FDSN:IU_ANMO_00_B_H_Z")!
inspect(sid.network(), content="IU")
let s = sid.to_string()   // 规范化输出
```

### 4.2 time.Time

- 存储：`Int64` 纳秒（自 Unix epoch）
- 从 miniSEED header 字段构造：`(nanos: UInt32, year: UInt16, doy: UInt16, hour: UInt8, min: UInt8, sec: UInt8)`，秒值 60 表示正闰秒
- 提供 proleptic Gregorian 儒略日转换；格式化 ISO8601（`2026-08-17T08:00:00.000000Z`）

### 4.3 miniseed3.FixedHeader（40 字节，全小端）

| 字段 | 偏移 | 大小 | 类型 |
|---|---|---|---|
| 记录头指示 | 0 | 2 | ASCII `"MS"` (77,83) |
| 格式版本 | 2 | 1 | UInt8 = 3 |
| 标志 | 3 | 1 | bit0 校准信号、bit1 时间标记可疑、bit2 时钟锁定 |
| 起始时间 | 4 | 11 | UInt32 ns @4、UInt16 year @8、UInt16 doy @10、UInt8 h @12、UInt8 min @13、UInt8 s @14 |
| 数据编码 | 15 | 1 | 见 4.4 |
| 采样率/周期 | 16 | 8 | Float64 LE，正=Hz、负=周期(秒)、0=无数据 |
| 样本数 | 24 | 4 | UInt32，0=仅头记录 |
| 记录 CRC | 28 | 4 | CRC-32C (Castagnoli) |
| 发布版本 | 32 | 1 | UInt8 |
| SID 长度 | 33 | 1 | UInt8 |
| Extra Headers 长度 | 34 | 2 | UInt16 |
| Data Payload 长度 | 36 | 4 | UInt32 |

总长 = 40 + SID长度 + Extra长度 + Payload长度（不允许填充）。

### 4.4 编码表

| 码 | 编码 |
|---|---|
| 0 | Text |
| 1 | Int16 (LE) |
| 3 | Int32 (LE) |
| 4 | Float32 (LE) |
| 5 | Float64 (LE) |
| 10 | STEIM-1（本期不解码，识别+报"未支持"诊断） |
| 11 | STEIM-2（同上） |
| 19 | STEIM-3（同上） |
| 100 | Opaque（保留原始字节） |

未知编码：识别但报 `UnsupportedEncoding` 诊断，不崩溃。

### 4.5 record.Record

- `header: miniseed3.FixedHeader`（含解析出的 SID、编码、采样率、时间等）
- `extra_headers: String`（JSON 原文，可再解析）
- `samples: Samples`（见 4.6）
- `raw: Bytes`（原始记录字节，用于 CRC 复核与回写）
- 提供 `start_time() / end_time() / sample_rate() / sample_count()` 便捷方法

### 4.6 样本表示

- Int16/Int32/Float32/Float64 统一解码为 `Array[Float64]`（波形处理友好）
- Text/Opaque/Steim 保留原始 `Bytes` 或报未支持
- 原始字节始终保存在 `record.raw`，不丢失原始数据

### 4.7 trace.Trace

- `sid: String`（规范化的 FDSN SID）
- `start_time: time.Time`、`end_time: time.Time`
- `sample_rate: Float64`（可小数）
- `samples: Array[Float64]`
- 由多记录按 (SID, 时间, 采样率) 分组、排序、拼接重建

### 4.8 quality.QualityReport

- `issues: Array[Issue]`，`Issue { severity, message, start, end }`
- 严重度：`Info / Warning / Error / Critical`（枚举）
- 指标：数据完整率、缺口数/总长、重叠数、重复记录数、最大振幅、均值、标准差、尖峰数、削波比例、常值区间数、时间连续性
- 综合评分：0-100

### 4.9 trigger.Event

- `sid`、`start_time`、`end_time`、`duration`
- `components: Array[String]`（多分量合并来源）
- `confidence: Float64`（0-1，基于峰值比值与时长）
- `trigger_type`：`Classic / Recursive`

## 5. miniSEED 3 解析器设计

- 迭代器式 `Reader`：输入 `Bytes`（文件整体读入或分块），逐记录产出 `Record` 或 `ParseError`
- 严格校验链：
  1. 剩余字节 ≥ 40
  2. `"MS"` 魔数
  3. version == 3
  4. 长度自洽：40 + sid_len + extra_len + payload_len ≤ 输入长度
  5. CRC-32C 全记录校验（计算时 CRC 字段清零）
  6. 采样率合法（非 NaN；0 表示无数据允许）
  7. 样本数 × 每样本字节 == payload 长度（对定长编码）
  8. SID 合法、编码已知
- 错误诊断枚举：`Truncated / BadMagic / BadVersion / BadCRC / BadSampleRate / BadEncoding / BadSid / LengthMismatch / UnsupportedEncoding / MalformedExtraHeaders`
- 错误分类上报而非 panic；单条坏记录不中断整体解析（可收集错误继续）

### CRC-32C

- 多项式 0x1EDC6F41（反向 0x82F63B78），Castagnoli，按 RFC 3309
- 表驱动实现；校验范围 = 完整记录（CRC 字段置零）

## 6. 连续波形重建

- 输入 `Array[Record]`（可跨文件收集）
- 按规范化 SID 分组 → 组内按 start_time 排序 → 依次拼接
- 检测项：
  - 缺口：`(next.start - prev.end) > 采样间隔`
  - 重叠：`next.start < prev.end`
  - 重复记录：起止与样本完全一致（或起始相同）
  - 采样率突变：相邻记录采样率不同
  - 时间漂移：拼接后累计期望位置与实际起始之差
- 输出 `Trace`；缺口不插值，样本保持原始序列，质量层负责标记

## 7. 质量检查规则

规则（可组合，`Array[@quality.rule]`）：

- `gap_rule`：缺口（按阈值，如 > N 个采样间隔）
- `overlap_rule`：重叠
- `duplicate_rule`：重复记录
- `clipping_rule`：饱和/削波检测
- `constant_rule`：长时间常值检测
- `spike_rule`：异常尖峰检测（基于相邻差分）
- `rate_change_rule`：采样率突变

严重度分级与综合评分逻辑集中在一个评分模块。

## 8. 波形预处理（signal）

- 去均值、去线性趋势（最小二乘）、波形归一化
- Hann / Tukey taper、波形切窗
- 重采样基础支持（线性插值，`basic` 档）
- 滑动 RMS、峰值绝对振幅、波形能量
- 峰度、偏度
- 饱和/削波检测、长时间常值检测（供 quality 复用）

## 9. STA/LTA 事件检测（trigger）

- Classic：滑动窗 STA/LTA 比值（绝对值包络与能量包络两种模式）
- Recursive：指数平滑递推
- 双阈值：触发阈值 + 解除阈值
- 最短事件持续时间、触发前后扩展（pre/post padding）
- 多分量事件合并：时间重叠归并
- 事件置信评分（0-1）
- 文档明确：检测结果为算法候选，不等同于专业机构发布的地震事件结论

## 10. CLI（cmd/main）

```
moonseis inspect   <file>            # 汇总：格式/记录数/源数/时间范围/样本数/CRC失败/缺口/事件
moonseis records   <file>            # 逐记录明细表
moonseis validate  <file>            # 逐记录校验，失败退出码非零
moonseis traces    <file>            # 波形段摘要
moonseis quality   <file>            # 质量报告
moonseis detect    <file>            # STA/LTA 事件列表
moonseis convert   <file> --format json|csv|geocsv|md|text
```

退出码约定：0=成功；校验类失败返回非零。

## 11. 输出格式（formats）

- JSON（元数据、质量、事件均可序列化）
- CSV / GeoCSV（波形段、事件）
- Markdown 报告（质量、inspect 摘要）
- 简单文本波形（ASCII）
- SARIF：预留接口，本期不实现完整适配

## 12. 测试策略

- fixtures 生成器（mbt 或独立脚本）构建合成 miniSEED 3 字节流：
  - 合法：各编码（Text/Int16/Int32/Float32/Float64/Opaque）、多记录、多 SID、含 Extra Headers
  - 非法：坏魔数、坏版本、截断、坏 CRC、坏 SID、坏采样率、长度不符、未知编码、样本数与 payload 不符
- 真实样本：`fixtures/real/`，存在则测试覆盖，缺失则跳过
- 每包单元测试 + `cmd/main` 集成测试 + CLI 冒烟测试
- CI：`moon check` / `moon test` 通过

## 13. 提交规划（≥12 个真实提交）

1. chore: initialize MoonSeis project
2. feat: add FDSN source identifier model
3. feat: implement source identifier parser
4. feat: add bounded binary reader
5. feat: implement miniSEED 3 fixed header parsing
6. feat: validate miniSEED CRC records
7. feat: decode uncompressed waveform samples
8. feat: reconstruct continuous waveform traces
9. feat: detect gaps overlaps and duplicate records
10. feat: add waveform quality metrics
11. feat: implement STA LTA event trigger
12. feat: add JSON CSV and GeoCSV output
13. feat: add MoonSeis command line interface
14. test: expand malformed record test coverage
15. docs: add examples and architecture documentation
16. ci: validate all MoonBit targets

## 14. 风险与备注

- 真实样本可能含 Steim 编码（阶段内不可解码），以 `UnsupportedEncoding` 诊断处理，不视为解析失败
- 采样率为 Float64 时需处理浮点比较容差
- 闰秒（秒=60）在时间转换中需明确定义
- 发布前需复查 Mooncakes.io 同名包，替换模块名与仓库链接
