# tvlive

自用 IPTV 直播源，每天自动更新。

## 快速开始

把下面任意一条复制到播放器（VLC / TVBox / TiviMate / 影视仓…）的「订阅」里就行：

| 我要看什么 | 用哪个地址 |
|---|---|
| 全部频道 | `https://raw.githubusercontent.com/pizom01/tvlive/main/tv.m3u` |
| **只要央视 + 卫视**（推荐） | `https://raw.githubusercontent.com/pizom01/tvlive/main/tv2.m3u` |
| 本地实测过、能播的 | `https://raw.githubusercontent.com/pizom01/tvlive/main/tv-live.m3u` |

> 国内直连经常打不开，那就用加速地址（见下一节）。

## 国内加速（复制这个更稳）

在原地址前面加一段前缀：

```
https://gh-proxy.com/https://raw.githubusercontent.com/pizom01/tvlive/main/tv2.m3u
```

备用的两条，一条不行换一条：

```
https://ghfast.top/https://raw.githubusercontent.com/pizom01/tvlive/main/tv2.m3u
https://cdn.jsdelivr.net/gh/pizom01/tvlive@main/tv2.m3u
```

实测速度（2026-11-14，同一台机器，拉 176 KB）：

| 地址 | 耗时 |
|---|---|
| 直连 | 13.6 ~ 16.5 秒 |
| gh-proxy.com | 2.1 秒 |
| ghfast.top | 2.1 秒 |
| jsDelivr | 4.4 秒（有缓存，更新会延迟） |

## 三个文件有什么区别

| 文件 | 内容 | 怎么更新 |
|---|---|---|
| `tv.m3u` | 全部频道，约 1400 条地址 | 每天 0 点自动 |
| `tv2.m3u` | 只保留央视 + 卫视，约 190 条 | 每天 0 点自动 |
| `tv-live.m3u` | 在本机实际测过、能播的地址 | 手动，不定期 |

每个频道最多带 3 个地址，第一个放不通会自动试下一个。

## 播不了怎么办

- **先换地址**：同一个频道在列表里有 2~3 条，播放器里手动切一下。
- **还是不行**：这些源本身寿命只有几天到几周，属于正常损耗，等第二天自动更新，或者用 `tv-live.m3u`。
- **整体都很卡**：换成 `tv2.m3u`，频道少但每个更有保障。

## 数据从哪来

自动合并下面三个公开源，优先级从上到下：

| 优先级 | 源 | 说明 |
|---|---|---|
| 1 | [vbskycn/iptv](https://github.com/vbskycn/iptv) | 6 小时更新，自带台标，实测存活率约 95% |
| 2 | [Guovin/iptv-api](https://github.com/Guovin/iptv-api) | 量大覆盖全，实测存活率约 40% |
| 3 | [hujingguang/ChinaIPTV](https://github.com/hujingguang/ChinaIPTV) | 港澳台/国际频道为主，境内能用的少 |

> 为什么列表里会有不能播的地址？因为 GitHub 的服务器在国外，在那里"测试能不能播"会把国内能看的频道全判成失效，所以自动流程只做合并，不做筛选。真正测过的版本是 `tv-live.m3u`。

## 自己维护

仓库结构：

```
tv.m3u           全量列表（自动生成，别手改）
tv2.m3u          央视+卫视（自动生成，别手改）
tv-live.m3u      本地实测快照（手动更新）
scripts/merge.ps1  合并脚本
.github/workflows/update.yml  每天 0 点的定时任务
```

本地手动生成一次：

```powershell
pwsh ./scripts/merge.ps1 -Out tv.m3u
pwsh ./scripts/merge.ps1 -Out tv2.m3u -CctvSat
```

常用调整：

- 加/减源：改 `scripts/merge.ps1` 里的 `$sources`
- 每频道保留几条地址：加 `-MaxUrls 5`
- 只要某几个分组：`-OnlyGroups 央视频道,港澳台频道`

## 说明

所有地址均转载自上述公开仓库，本仓库只做聚合整理，不托管任何流媒体内容。公共源时效性差，播放失败属正常现象。
