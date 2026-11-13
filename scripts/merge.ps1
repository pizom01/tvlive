param(
    [string]$Out = "tv.m3u",
    [int]$MaxUrls = 3
)

# 多源合并：按优先级取地址，同一频道最多保留 $MaxUrls 条
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Net.Http -ErrorAction SilentlyContinue
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$sources = @(
    @{ name = 'vbskycn'; url = 'https://live.zbds.top/tv/iptv4.m3u' },
    @{ name = 'guovin';  url = 'https://raw.githubusercontent.com/Guovin/iptv-api/gd/output/result.m3u' },
    @{ name = 'chinatv'; url = 'https://raw.githubusercontent.com/hujingguang/ChinaIPTV/main/cnTV_AutoUpdate.m3u8' }
)

$epg = 'http://epg.51zmt.top:8000/e.xml'
$utf8Strict = New-Object System.Text.UTF8Encoding($false, $true)
$utf8Loose = New-Object System.Text.UTF8Encoding($false)
$gbk = [Text.Encoding]::GetEncoding(936)
$junk = '^(\d{4}年|\d{4}-\d{2}-\d{2}|更新时间)'
$hmt = '香港|澳门|澳门|台湾|凤凰|澳视|翡翠|明珠|TVB|ViuTV|HOY|RTHK|TVBS|东森|中视|民视|华视|台视|中天|三立|八大|非凡|寰宇'
$weiShi = [string][char]0x536B + [string][char]0x89C6

function Get-Bytes([string]$url) {
    $client = New-Object System.Net.Http.HttpClient
    $client.Timeout = [TimeSpan]::FromSeconds(30)
    try {
        $client.DefaultRequestHeaders.TryAddWithoutValidation('User-Agent', 'Mozilla/5.0') | Out-Null
        return $client.GetByteArrayAsync($url).Result
    } finally {
        $client.Dispose()
    }
}

function Get-Lines([byte[]]$raw) {
    # 上游列表逐行混用 UTF-8 / GBK，按行单独解码
    $lines = New-Object System.Collections.Generic.List[string]
    $start = 0
    for ($i = 0; $i -lt $raw.Length; $i++) {
        if ($raw[$i] -ne 10) { continue }
        $len = $i - $start
        if ($len -gt 0 -and $raw[$i - 1] -eq 13) { $len-- }
        $slice = New-Object byte[] $len
        if ($len -gt 0) { [Array]::Copy($raw, $start, $slice, 0, $len) }
        try { $lines.Add($utf8Strict.GetString($slice)) } catch { $lines.Add($gbk.GetString($slice)) }
        $start = $i + 1
    }
    if ($start -lt $raw.Length) {
        $slice = New-Object byte[] ($raw.Length - $start)
        [Array]::Copy($raw, $start, $slice, 0, $slice.Length)
        try { $lines.Add($utf8Strict.GetString($slice)) } catch { $lines.Add($gbk.GetString($slice)) }
    }
    return $lines
}

function Get-Key([string]$name) {
    $k = $name -replace '[\s\-_]+', ''
    $k = $k -replace '(?i)cctv(\d+)', 'CCTV$1'
    return $k.ToUpperInvariant()
}

function Get-Group([string]$name) {
    if ($name -match '(?i)^CCTV') { return '央视频道' }
    if ($name.EndsWith($weiShi)) { return '卫视频道' }
    if ($name -match $hmt) { return '港澳台频道' }
    return '其他频道'
}

$channels = [ordered]@{}
$seenUrls = New-Object 'System.Collections.Generic.HashSet[string]'

foreach ($src in $sources) {
    try {
        $raw = Get-Bytes $src.url
    } catch {
        Write-Host ("warn: {0} fetch failed: {1}" -f $src.name, $_.Exception.Message)
        continue
    }
    $lines = Get-Lines $raw
    $count = 0
    $name = $null
    foreach ($line in $lines) {
        $t = $line.Trim()
        if ($t -eq '') { continue }
        if ($t.StartsWith('#EXTINF')) {
            $idx = $t.LastIndexOf(',')
            if ($idx -lt 0) { continue }
            $name = $t.Substring($idx + 1).Trim()
            continue
        }
        if ($t.StartsWith('#')) { continue }
        if (-not $name) { continue }
        if ($name -match $junk) { $name = $null; continue }
        $key = Get-Key $name
        if (-not $channels.Contains($key)) {
            $channels[$key] = @{ name = $name; urls = New-Object System.Collections.Generic.List[string] }
        }
        foreach ($u in ($t -split '#\s*(?=https?://)')) {
            if ($channels[$key].urls.Count -ge $MaxUrls) { break }
            if (-not $u.StartsWith('http')) { continue }
            if ($seenUrls.Contains($u)) { continue }
            [void]$seenUrls.Add($u)
            $channels[$key].urls.Add($u)
            $count++
        }
        $name = $null
    }
    Write-Host ("info: {0} contributed {1} urls" -f $src.name, $count)
}

if ($channels.Count -eq 0) {
    Write-Error 'no channel collected, keeping existing tv.m3u'
    exit 1
}

$groups = [ordered]@{ '央视频道' = @(); '卫视频道' = @(); '港澳台频道' = @(); '其他频道' = @() }
foreach ($key in $channels.Keys) {
    $entry = $channels[$key]
    if ($entry.urls.Count -eq 0) { continue }
    $groups[(Get-Group $entry.name)] += , $entry
}

$outLines = New-Object System.Collections.Generic.List[string]
$outLines.Add('#EXTM3U x-tvg-url="' + $epg + '"')
$total = 0
foreach ($gName in $groups.Keys) {
    $items = $groups[$gName]
    if (-not $items -or $items.Count -eq 0) { continue }
    $outLines.Add('')
    foreach ($entry in ($items | Sort-Object { $_.name })) {
        foreach ($u in $entry.urls) {
            $outLines.Add('#EXTINF:-1 group-title="' + $gName + '",' + $entry.name)
            $outLines.Add($u)
            $total++
        }
    }
}

$resolved = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Out)
[System.IO.File]::WriteAllLines($resolved, $outLines, $utf8Loose)
Write-Host ("info: wrote {0} with {1} channels / {2} urls" -f $Out, $channels.Count, $total)
