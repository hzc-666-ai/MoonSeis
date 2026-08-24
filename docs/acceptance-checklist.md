# MoonSeis 正式验收自查清单

本清单用于正式验收前快速确认仓库是否具备可复现、可运行、可展示的证据。

## 必跑命令

```powershell
moon check
moon test
moon run cmd/main -- inspect fixtures/example.mseed
moon run cmd/main -- report fixtures/example.mseed json > analysis.json
moon run cmd/main -- convert fixtures/example.mseed html > report.html
```

## 仓库材料

- [x] 根目录包含 `README.md`，说明项目目标、功能、命令和限制
- [x] 根目录包含 `LICENSE`，当前为 Apache-2.0
- [x] 根目录包含 `申报书.md`
- [x] GitHub Actions 执行 `moon check`、`moon test` 和 CLI 烟测
- [x] 示例数据位于 `fixtures/example.mseed`
- [x] HTML 报告和 JSON 报告均可从示例数据生成

## 验收前人工确认

- [ ] GitHub 默认分支指向包含最新提交的 `master`
- [ ] GitHub Actions 最近一次运行通过
- [ ] 按比赛要求发布到 mooncakes.io，并确认包名为 `hzc-666-ai/moonseis`
- [ ] 提交材料中的仓库链接为 `https://github.com/hzc-666-ai/MoonSeis.git`
- [ ] 如使用额外真实地震数据，补充数据来源和许可证说明

## 可展示亮点

- 纯 MoonBit miniSEED 3 解析链路
- Trace 重建、分段诊断、质量评分、STA/LTA 事件候选检测
- 自包含 HTML 波形报告，支持事件区间高亮
- 完整 JSON 分析报告，适合 CI、前端和自动化平台集成
