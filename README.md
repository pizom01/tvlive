# tvlive

自用 IPTV 订阅。每天北京时间 0 点由 GitHub Actions 自动合并三个公开源，输出 `tv.m3u`。

## 订阅地址

```
https://raw.githubusercontent.com/pizom01/tvlive/main/tv.m3u
```

（国内访问不通的话，把 `raw.githubusercontent.com` 换成任意 GitHub 加速镜像前缀）

## 合并的三个源

| 优先级 | 源 | 说明 |
|---|---|---|
| 1 | [vbskycn/iptv](https://github.com/vbskycn/iptv) | 6 小时更新，自带台标/EPG，实测存活率约 95% |
| 2 | [Guovin/iptv-api](https://github.com/Guovin/iptv-api) | 每天测速筛选，量大覆盖全，实测存活率约 40% |
| 3 | [hujingguang/ChinaIPTV](https://github.com/hujingguang/ChinaIPTV) | 港澳台/国际频道为主，境内实测存活率低（约 15%），仅作补充 |

优先级高的源排在同频道的前面，播放器拉飞了会自动往下试。每个频道最多保留 3 个地址。

## 目录结构

```
tv.m3u                     # 生成物，别手改，会被 Action 覆盖
scripts/merge.ps1          # 合并脚本（PowerShell，Actions 与本地都能跑）
.github/workflows/update.yml
```

本地想手动生成一次：

```powershell
pwsh ./scripts/merge.ps1 -Out tv.m3u
```

## 为什么 Action 里不做可用性探测

GitHub Actions 的 runner 在境外，而这些源绝大多数做了地域/运营商限制。在 runner 上探测会把国内能正常播放的频道误判成失效，产出一份"看起来干净但缺频道"的列表。

所以这里的分工是：

- **仓库**：只做合并、去重、频道名归一化、分组，保证覆盖率。
- **本地**：用 [IPTV-API 桌面端](https://github.com/Guovin/iptv-api) 在真实网络下测速筛选，得到可用性最高的版本。

## 调整

- 加/减源：改 `scripts/merge.ps1` 里的 `$sources` 数组。
- 每频道地址数：`-MaxUrls 5`。
- 嫌"其他频道"太多：目前脚本输出央视/卫视/港澳台/其他四个分组，按需在 `$groups` 里删掉。

## 注意

所有地址均来自上述公开仓库的转载索引，本仓库只做聚合，不托管任何流媒体内容。公共源寿命通常只有几天到几周，播放失败属于常态，换一个地址或等下一次自动更新即可。
