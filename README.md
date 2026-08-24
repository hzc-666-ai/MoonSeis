# MoonSeis

MoonSeis 是一个使用 [MoonBit](https://www.moonbitlang.com/) 编写的 miniSEED 3 波形分析工具包。它面向地震波形数据的轻量处理流程，提供 miniSEED 记录解析、连续波形重建、质量检查、信号预处理、STA/LTA 事件候选检测，以及多格式命令行输出。

> 注意：MoonSeis 输出的事件检测结果是算法候选，不是权威地震结论，也不应直接用于安全关键决策。

## 功能特性

- **miniSEED 3 解析**：支持固定头、FDSN Source Identifier、extra headers 与 CRC-32C 校验
- **样本数据解码**：支持 Int16、Int32、Float32、Float64、Text、Opaque 数据类型
- **Trace 重建**：按 SID 分组，并按时间顺序构建连续波形 trace
- **时间段诊断**：检测 gap、overlap、duplicate、sample-rate change 等问题
- **质量评估**：内置 clipping、constant signal、spike 等质量规则与评分
- **信号处理**：支持 demean、detrend、normalize、Hann taper、RMS、统计量与基础重采样
- **事件候选检测**：支持 Classic / Recursive STA/LTA，并输出带置信度的事件区间
- **多格式输出**：支持 JSON、CSV、GeoCSV、Markdown 和终端文本波形输出
- **跨平台 CLI**：默认使用 native 后端，支持 Windows 与类 Unix 环境读取本地文件

## 快速开始

### 环境要求

- 安装 MoonBit 工具链
- 使用项目默认 native 后端

### 本地验证

在项目根目录运行：

```powershell
moon check
moon test
moon run cmd/main -- inspect fixtures/example.mseed
```

示例文件 `fixtures/example.mseed` 包含 3 条带合法 CRC 的 Int16 记录，可组成 2 条 source trace。

## 命令行用法

通用格式：

```text
moon run cmd/main -- <command> <file> [format]
```

| 命令 | 作用 |
| --- | --- |
| `inspect` | 汇总记录、trace 和分段问题 |
| `records` | 按记录输出 SID、开始时间、采样数和采样率 |
| `validate` | 校验每条记录并输出错误摘要 |
| `traces` | 输出重建后的 trace 摘要 |
| `quality` | 执行默认质量规则并生成评分 |
| `detect` | 对每条 trace 运行 Classic STA/LTA 事件候选检测 |
| `convert` | 转换为 `json`、`csv`、`geocsv`、`md`、`html` 或 `text` |

常用示例：

```powershell
moon run cmd/main -- records fixtures/example.mseed
moon run cmd/main -- validate fixtures/example.mseed
moon run cmd/main -- quality fixtures/example.mseed
moon run cmd/main -- detect fixtures/example.mseed
moon run cmd/main -- convert fixtures/example.mseed csv
moon run cmd/main -- convert fixtures/example.mseed html > report.html
```

退出码约定：

| 退出码 | 含义 |
| --- | --- |
| `0` | 执行成功 |
| `1` | 参数错误或文件读取错误 |
| `2` | `validate` 发现无效记录 |

## 库入口

根包提供一个简洁 facade，适合快速解析记录或直接构建 trace：

```moonbit
let results = @moonseis.parse_records(raw)
let traces = @moonseis.traces_from_bytes(raw)
println(@moonseis.version())
```

说明：

- `parse_records` 会保留逐条解析结果，适合定位每条记录的错误
- `traces_from_bytes` 会跳过错误记录，只使用成功解析的数值记录构建 trace
- 更细粒度的能力位于 `record`、`trace`、`quality`、`signal`、`trigger` 和 `formats` 等子包

## 项目结构

```text
binary/             little-endian 字节读写
miniseed3/          miniSEED 3 固定头与 CRC-32C
encoding/           样本数据解码
record/             完整记录解析与流式迭代
trace/              trace 重建与分段诊断
quality/            质量指标、质量规则与评分
signal/             波形预处理与统计函数
trigger/            STA/LTA 事件候选检测
formats/            JSON / CSV / GeoCSV / Markdown / HTML / Text 输出适配器
cmd/main/           native 命令行入口
internal/fixtures/  测试 fixture 生成器
fixtures/           可直接运行的示例数据
docs/               设计、实施计划与架构说明
```

更多内部设计见 [`docs/architecture.md`](docs/architecture.md)。

## 当前限制

- 尚未实现 Steim-1、Steim-2、Steim-3 解压；遇到这些编码会返回 typed error
- 尚未实现 miniSEED 2.4 读取、Wasm 波形查看器和 SARIF 输出
- CLI 的非 Windows native 文件读取目前只保证 ASCII 路径；Windows 支持宽字符路径
- 基础重采样使用线性插值，不替代专业抗混叠重采样流程

## 开发验证

推荐在提交前执行：

```powershell
moon check --warn-list +73
moon test
moon info
moon fmt
moon check
moon test
```

CI 会在 push 和 pull request 上执行 `moon check` 与 `moon test`。

## 许可证

本项目使用 Apache-2.0 许可证，详见 [`LICENSE`](LICENSE)。
