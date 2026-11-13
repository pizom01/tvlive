# tvlive

自用 IPTV 订阅。每天北京时间 0 点由 GitHub Actions 自动合并三个公开源。

## 订阅地址

| 文件 | 内容 | 更新方式 |
|---|---|---|
| `tv.m3u` | 全部频道（央视 + 卫视 + 港澳台 + 其他） | 每天 0 点自动 |
| `tv2.m3u` | **只含央视频道 + 卫视频道** | 每天 0 点自动 |
| `tv-live.m3u` | 本地实测快照（拉不通的已剔除） | 手动，需要时重新导出 |

```
https://raw.githubusercontent.com/pizom01/tvlive/main/tv.m3u
https://raw.githubusercontent.com/pizom01/tvlive/main/tv2.m3u
https://raw.githubusercontent.com/pizom01/tvlive/main/tv-live.m3u
```

（国内访问不通的话，用下面的加速方式）

## 国内访问加速

`raw.githubusercontent.com` 在国内经常很慢甚至直连不通，可以套一层代理前缀。实测数据（2026-11-14，本机联通线路，拉取 172 KB 的 `tv.m3u`）：

| 方式 | 耗时 | 速度 | 说明 |
|---|---|---|---|
| 直连 | 13.6 ~ 16.5 s | ~11 KB/s | 经常不通或极慢 |
| `https://gh-proxy.com/` | 2.1 s | 81 KB/s | **推荐** |
| `https://ghfast.top/` | 2.1 s | 82 KB/s | **推荐**，可作备份 |
| `https://cdn.jsdelivr.net/gh/pizom01/tvlive@main/` | 4.4 s | 39 KB/s | CDN，有缓存（最长 12 小时），更新会延迟 |
| `https://ghproxy.net/` | 12.4 s | 14 KB/s | 能用但慢 |
| `https://github.moeyy.xyz/` | 超时 | — | 实测不通 |
| `https://mirror.ghproxy.com/` | 超时 | — | 实测不通 |

用法：把原始地址整段拼在代理前缀后面；jsDelivr 则是换成 `gh/用户名/仓库@分支/文件名` 的写法。

```bash
# 代理前缀版（推荐 gh-proxy）
https://gh-proxy.com/https://raw.githubusercontent.com/pizom01/tvlive/main/tv2.m3u
https://ghfast.top/https://raw.githubusercontent.com/pizom01/tvlive/main/tv2.m3u

# jsDelivr 版
https://cdn.jsdelivr.net/gh/pizom01/tvlive@main/tv2.m3u

# 另外两个文件同理，只改最后的文件名
https://gh-proxy.com/https://raw.githubusercontent.com/pizom01/tvlive/main/tv.m3u
https://gh-proxy.com/https://raw.githubusercontent.com/pizom01/tvlive/main/tv-live.m3u
```

> 这些代理站都是第三方服务，随时可能失效、限速或加广告页；上面的数据只是某一时段的单次测量。如果播放器支持填多个订阅地址，建议「直连 + gh-proxy」两条一起填，一条挂了另一条顶上。

## 合并的三个源

| 优先级 | 源 | 说明 |
|---|---|---|
| 1 | [vbskycn/iptv](https://github.com/vbskycn/iptv) | 6 小时更新，自带台标/EPG，实测存活率约 95% |
| 2 | [Guovin/iptv-api](https://github.com/Guovin/iptv-api) | 每天测速筛选，量大覆盖全，实测存活率约 40% |
| 3 | [hujingguang/ChinaIPTV](https://github.com/hujingguang/ChinaIPTV) | 港澳台/国际频道为主，境内实测存活率低（约 15%），仅作补充 |

优先级高的源排在同频道的前面，播放器拉飞了会自动往下试。每个频道最多保留 3 个地址。

## 目录结构

```
tv.m3u                     # 生成物（全量），别手改，会被 Action 覆盖
tv2.m3u                    # 生成物（仅央视+卫视），同上
tv-live.m3u                # 本地实测快照，Action 不碰，手动更新
scripts/merge.ps1          # 合并脚本（PowerShell，Actions 与本地都能跑）
.github/workflows/update.yml
```

本地想手动生成一次：

```powershell
pwsh ./scripts/merge.ps1 -Out tv.m3u
pwsh ./scripts/merge.ps1 -Out tv2.m3u -CctvSat
```

## 为什么 Action 里不做可用性探测

GitHub Actions 的 runner 在境外，而这些源绝大多数做了地域/运营商限制。在 runner 上探测会把国内能正常播放的频道误判成失效，产出一份"看起来干净但缺频道"的列表。

所以这里的分工是：

- **仓库**：只做合并、去重、频道名归一化、分组，保证覆盖率。
- **本地**：用 [IPTV-API 桌面端](https://github.com/Guovin/iptv-api) 在真实网络下测速筛选，得到 `tv-live.m3u`（实测快照，需要时重新导出后手动提交）。

## 调整

- 加/减源：改 `scripts/merge.ps1` 里的 `$sources` 数组（每项可带 `fallback` 备用镜像）。
- 每频道地址数：`-MaxUrls 5`。
- 只要央视+卫视：加 `-CctvSat`；要自定义分组用 `-OnlyGroups 央视频道,港澳台频道`。

## 注意

所有地址均来自上述公开仓库的转载索引，本仓库只做聚合，不托管任何流媒体内容。公共源寿命通常只有几天到几周，播放失败属于常态，换一个地址或等下一次自动更新即可。
