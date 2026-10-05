<#
.SYNOPSIS
    一键快速创建 Hugo 博客文章（Page Bundle 模式）。
.DESCRIPTION
    自动创建文章独立目录及其专属 assets 附件文件夹，生成带 Frontmatter 的 index.md，并在 Obsidian 中自动打开。
.EXAMPLE
    .\new-post.ps1
    .\new-post.ps1 -Title "李宏毅机器学习第二周" -Section study
#>

param(
    [string]$Title = "",
    [string]$Section = "",
    [string]$Slug = ""
)

$siteRoot = $PSScriptRoot
$today = Get-Date

# 1. 选择分类
if ([string]::IsNullOrWhiteSpace($Section)) {
    Write-Host ""
    Write-Host "=== 新建博客文章 (Page Bundle 模式) ===" -ForegroundColor Cyan
    Write-Host "[1] journal  (日志 - 流水账、每日记录)"
    Write-Host "[2] study    (学习 - 课程笔记、技术教程)"
    Write-Host "[3] thoughts (想法 - 思考感悟、随笔)"
    $choice = Read-Host "请选择文章分类 [1-3] (默认: 1)"
    switch ($choice) {
        "2" { $Section = "study" }
        "3" { $Section = "thoughts" }
        default { $Section = "journal" }
    }
}

# 2. 输入标题
if ([string]::IsNullOrWhiteSpace($Title)) {
    $Title = Read-Host "请输入文章标题"
    if ([string]::IsNullOrWhiteSpace($Title)) {
        $Title = "未命名文章"
    }
}

# 3. 确定目录名 (Slug)
if ([string]::IsNullOrWhiteSpace($Slug)) {
    $safeTitle = ($Title -replace '[\\/:*?"<>| ]', '-').Trim('-')
    if ($Section -eq "journal") {
        $defaultSlug = $today.ToString("yyyy-MM-dd")
    } else {
        $defaultSlug = "$($today.ToString('yyyy-MM-dd'))-$safeTitle"
    }

    $inputSlug = Read-Host "请输入文章目录名 [留空默认: $defaultSlug]"
    if ([string]::IsNullOrWhiteSpace($inputSlug)) {
        $Slug = $defaultSlug
    } else {
        $Slug = ($inputSlug -replace '[\\/:*?"<>| ]', '-').Trim('-')
    }
}

$postDir = Join-Path $siteRoot "content\$Section\$Slug"
$assetsDir = Join-Path $postDir "assets"
$indexPath = Join-Path $postDir "index.md"

if (Test-Path $postDir) {
    Write-Warning "目录已存在: $postDir"
    $overwrite = Read-Host "是否在此目录中打开编辑？(Y/n)"
    if ($overwrite -eq 'n' -or $overwrite -eq 'N') {
        Write-Host "已取消。" -ForegroundColor Yellow
        exit 0
    }
} else {
    New-Item -ItemType Directory -Path $assetsDir -Force | Out-Null
}

# 4. 生成 index.md 内容
if (-not (Test-Path $indexPath)) {
    $defaultTag = switch ($Section) {
        "journal" { "日志" }
        "study" { "学习" }
        "thoughts" { "想法" }
        default { "随笔" }
    }

    $dateStr = $today.ToString("yyyy-MM-dd")
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("---")
    [void]$sb.AppendLine("title: `"$Title`"")
    [void]$sb.AppendLine("date: $dateStr")
    [void]$sb.AppendLine("tags:")
    [void]$sb.AppendLine("  - $defaultTag")
    [void]$sb.AppendLine("description: `"`"")
    [void]$sb.AppendLine("---")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("")

    [System.IO.File]::WriteAllText($indexPath, $sb.ToString(), [System.Text.Encoding]::UTF8)
    Write-Host "`n文章已成功创建！" -ForegroundColor Green
    Write-Host "  文件路径: $indexPath" -ForegroundColor DarkGray
    Write-Host "  附件目录: $assetsDir`n" -ForegroundColor DarkGray
} else {
    Write-Host "文件已存在，直接打开..." -ForegroundColor Yellow
}

# 5. 尝试在 Obsidian 中打开
$relPath = "content/$Section/$Slug/index.md"
$encodedRel = [System.Uri]::EscapeDataString($relPath)
$obsidianUri = "obsidian://open?vault=MyBlog`&file=$encodedRel"

try {
    Start-Process $obsidianUri -ErrorAction Stop
} catch {
    Invoke-Item $indexPath
}
