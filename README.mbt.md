# MoonSeis

[![CI](https://github.com/hzc-666-ai/MoonSeis/actions/workflows/ci.yml/badge.svg)](https://github.com/hzc-666-ai/MoonSeis/actions/workflows/ci.yml)

MoonSeis 是一个以 MoonBit 编写的 miniSEED 3 波形工具包，提供记录解析、
连续波形重建、质量检查、信号预处理和 STA/LTA 事件候选检测。项目默认使用
native 后端，并附带可直接运行的命令行工具。

> 事件检测结果只是算法候选，不是权威地震结论，也不应直接用于安全关键决策。

## 已实现功能

- miniSEED 3 固定头、FDSN Source Identifier、extra headers 与 CRC-32C 校验
- Int16、Int32、Float32、Float64、Text、Opaque 数据解码
- 按 SID 分组和按时间排序的 Trace 构建
- gap、overlap、duplicate、sample-rate change 检测
- clipping、constant signal、spike 等质量规则与评分
- demean、detrend、normalize、Hann taper、RMS、统计量与基础重采样
- Classic / Recursive STA/LTA 及带置信度的事件区间
- JSON、CSV、GeoCSV、Markdown 和终端波形输出
- Windows 与类 Unix native CLI 文件读取

## 快速开始

需要安装当前 MoonBit 工具链。在项目根目录运行：

```powershell
moon check
moon test
moon run cmd/main -- inspect fixtures/example.mseed
```

示例文件 `fixtures/example.mseed` 包含 3 条带合法 CRC 的 Int16 记录，组成
2 条 source trace。

## CLI

```text
moon run cmd/main -- <command> <file> [format]
```

| 命令 | 作用 |
|---|---|
| `inspect` | 汇总记录、trace 和分段问题 |
| `records` | 按记录输出 SID、开始时间、采样数和采样率 |
| `validate` | 校验每条记录并输出错误摘要 |
| `traces` | 输出重建后的 trace 摘要 |
| `quality` | 执行默认质量规则并评分 |
| `detect` | 对每条 trace 运行 Classic STA/LTA |
| `convert` | 转换为 `json`、`csv`、`geocsv`、`md`、`html` 或 `text` |
| `report` | 输出完整的 JSON 分析报告 |

退出码：成功为 0；参数或文件错误为 1；`validate` 发现无效记录时为 2。

常用示例：

```powershell
moon run cmd/main -- records fixtures/example.mseed
moon run cmd/main -- validate fixtures/example.mseed
moon run cmd/main -- quality fixtures/example.mseed
moon run cmd/main -- detect fixtures/example.mseed
moon run cmd/main -- convert fixtures/example.mseed csv
moon run cmd/main -- convert fixtures/example.mseed html > report.html
moon run cmd/main -- report fixtures/example.mseed json > analysis.json
```

## 库入口

根包提供最小 facade：

```moonbit nocheck
let results = @moonseis.parse_records(raw)
let traces = @moonseis.traces_from_bytes(raw)
println(@moonseis.version())
```

需要保留逐条错误时使用 `parse_records`；`traces_from_bytes` 会跳过错误记录，
只用成功解析的数值记录构建 trace。更细粒度的功能位于 `record`、`trace`、
`quality`、`signal`、`trigger` 和 `formats` 子包。

## 项目结构

```text
binary/             little-endian 字节读写
miniseed3/          固定头与 CRC-32C
encoding/           样本解码
record/             完整记录解析与流迭代
trace/              trace 重建与分段诊断
quality/            质量指标、规则与评分
signal/             波形预处理与统计
trigger/            STA/LTA 事件检测
formats/            输出适配器
cmd/main/           native CLI
internal/fixtures/  测试 fixture 生成器
fixtures/           可直接运行的示例数据
docs/               设计、实施计划与架构说明
```

更多内部设计见 `docs/architecture.md`。

## 验收演示

正式验收时可以直接按下面顺序演示：

```powershell
moon check
moon test
moon run cmd/main -- inspect fixtures/example.mseed
moon run cmd/main -- report fixtures/example.mseed json > analysis.json
moon run cmd/main -- convert fixtures/example.mseed html > report.html
```

其中 `analysis.json` 适合机器校验，`report.html` 可直接打开查看波形和事件高亮。

## 验收准备

当前仓库已提供正式验收常用证据：

- 可复现构建与测试：`moon check`、`moon test`
- 可运行 CLI：`inspect`、`validate`、`quality`、`detect`、`convert`、`report`
- 可视化产物：`convert ... html` 生成自包含 HTML 报告
- 机器可读产物：`report ... json` 输出完整分析报告，便于 CI、前端或二次处理接入
- GitHub Actions：CI 会执行 MoonBit 检查、测试和 CLI 烟测

正式验收前还建议确认：仓库默认分支为 `master`，GitHub Actions 最近一次运行通过，并按比赛要求完成 mooncakes.io 发布。

## 当前限制

- 尚未实现 Steim-1、Steim-2、Steim-3 解压；遇到这些编码会返回 typed error
- 尚未实现 miniSEED 2.4、Wasm 波形查看器和 SARIF 输出
- CLI 的非 Windows native 文件读取目前只保证 ASCII 路径；Windows 支持宽字符路径
- 基础重采样使用线性插值，不替代专业抗混叠重采样流程

## 开发验证

```powershell
moon check --warn-list +73
moon test
moon info
moon fmt
moon check
moon test
```

CI 会在 push 和 pull request 上执行 `moon check` 与 `moon test`。

## License

Apache-2.0，见 `LICENSE`。
