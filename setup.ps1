#requires -version 5.1
<#
.SYNOPSIS
    三省六部系统 Windows 初始化脚本
.DESCRIPTION
    自动完成以下操作：
    1. 检查 Python/Node.js 依赖
    2. 创建 Agent 工作空间目录
    3. 复制 SKILL.md 到各 Agent 工作空间
    4. 复制 kanban_update.py 到各 Agent 工作空间
    5. 同步 Agent 配置
.PARAMETER SkipDeps
    跳过依赖检查
.PARAMETER AgentIds
    指定要初始化的 Agent ID 列表（默认全部）
.EXAMPLE
    .\setup.ps1
    .\setup.ps1 -SkipDeps
    .\setup.ps1 -AgentIds @('taizi', 'zhongshu')
#>

param(
    [switch]$SkipDeps,
    [string[]]$AgentIds = @('taizi', 'zhongshu', 'menxia', 'shangshu', 'libu', 'hubu', 'bingbu', 'xingbu', 'gongbu', 'libu_hr', 'zaochao')
)

$ErrorActionPreference = 'Stop'

# ── 颜色输出 ──
function Write-Step { param($msg) Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-OK   { param($msg) Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn { param($msg) Write-Host "  [!!] $msg" -ForegroundColor Yellow }
function Write-Err  { param($msg) Write-Host "  [XX] $msg" -ForegroundColor Red }

# ── 路径配置 ──
$OCLAW_HOME = Join-Path $env:USERPROFILE '.openclaw'
$REPO_ROOT = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host @"

╔══════════════════════════════════════════════════════╗
║   三省六部 · 多 Agent 编排系统 — Windows 初始化      ║
╚══════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

# ══ 1. 依赖检查 ══
if (-not $SkipDeps) {
    Write-Step '检查依赖...'

    # Python
    try {
        $pyVer = python --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-OK "Python: $pyVer"
        } else {
            Write-Err 'Python 未安装或不在 PATH 中'
            Write-Host '  请安装 Python 3.9+: https://www.python.org/downloads/'
            exit 1
        }
    } catch {
        Write-Err 'Python 未安装或不在 PATH 中'
        exit 1
    }

    # Node.js
    try {
        $nodeVer = node --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-OK "Node.js: $nodeVer"
        } else {
            Write-Warn 'Node.js 未安装（仅前端构建需要）'
        }
    } catch {
        Write-Warn 'Node.js 未安装（仅前端构建需要）'
    }

    # OpenClaw
    try {
        $ocVer = openclaw --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-OK "OpenClaw: $ocVer"
        } else {
            Write-Warn 'OpenClaw 未检测到，请确认已安装'
        }
    } catch {
        Write-Warn 'OpenClaw 未检测到，请确认已安装'
    }
}

# ══ 2. 创建 Agent 工作空间目录 ══
Write-Step '创建 Agent 工作空间...'

foreach ($agentId in $AgentIds) {
    $wsDir = Join-Path $OCLAW_HOME "workspace-$agentId"
    $skillsDir = Join-Path $wsDir 'skills\kanban_update'

    # 创建目录
    New-Item -ItemType Directory -Path $skillsDir -Force | Out-Null
    Write-OK "workspace-$agentId/skills/kanban_update/"
}

# ══ 3. 复制 SKILL.md ══
Write-Step '复制 SKILL.md...'

$skillMdSrc = Join-Path $REPO_ROOT 'skills\kanban_update\SKILL.md'
if (Test-Path $skillMdSrc) {
    foreach ($agentId in $AgentIds) {
        $skillMdDst = Join-Path $OCLAW_HOME "workspace-$agentId\skills\kanban_update\SKILL.md"
        Copy-Item $skillMdSrc $skillMdDst -Force
        Write-OK "workspace-$agentId/skills/kanban_update/SKILL.md"
    }
} else {
    Write-Err "SKILL.md 不存在: $skillMdSrc"
}

# ══ 4. 复制 kanban_update.py ══
Write-Step '复制 kanban_update.py...'

$kanbanSrc = Join-Path $REPO_ROOT 'scripts\kanban_update.py'
if (Test-Path $kanbanSrc) {
    foreach ($agentId in $AgentIds) {
        $kanbanDst = Join-Path $OCLAW_HOME "workspace-$agentId\skills\kanban_update\kanban_update.py"
        Copy-Item $kanbanSrc $kanbanDst -Force
        Write-OK "workspace-$agentId/skills/kanban_update/kanban_update.py"
    }
} else {
    Write-Err "kanban_update.py 不存在: $kanbanSrc"
}

# ══ 5. 复制其他脚本 ══
Write-Step '复制辅助脚本...'

$scriptsToCopy = @('file_lock.py', 'utils.py')
foreach ($script in $scriptsToCopy) {
    $scriptSrc = Join-Path $REPO_ROOT "scripts\$script"
    if (Test-Path $scriptSrc) {
        foreach ($agentId in $AgentIds) {
            $scriptDst = Join-Path $OCLAW_HOME "workspace-$agentId\skills\kanban_update\$script"
            Copy-Item $scriptSrc $scriptDst -Force
        }
        Write-OK "$script (all agents)"
    }
}

# ══ 6. 初始化数据目录 ══
Write-Step '初始化数据目录...'

$dataDir = Join-Path $REPO_ROOT 'data'
New-Item -ItemType Directory -Path $dataDir -Force | Out-Null

# 确保 tasks_source.json 存在
$tasksFile = Join-Path $dataDir 'tasks_source.json'
if (-not (Test-Path $tasksFile)) {
    '[]' | Out-File -FilePath $tasksFile -Encoding utf8
    Write-OK 'data/tasks_source.json (created)'
} else {
    Write-OK 'data/tasks_source.json (exists)'
}

# 确保 agent_config.json 存在
$agentConfigFile = Join-Path $dataDir 'agent_config.json'
if (-not (Test-Path $agentConfigFile)) {
    $defaultConfig = @{
        dispatchChannel = 'feishu'
        agents = @()
    }
    $defaultConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $agentConfigFile -Encoding utf8
    Write-OK 'data/agent_config.json (created)'
} else {
    Write-OK 'data/agent_config.json (exists)'
}

# ══ 7. 同步 Agent 配置 ══
Write-Step '同步 Agent 配置...'

$syncScript = Join-Path $REPO_ROOT 'scripts\sync_agent_config.py'
if (Test-Path $syncScript) {
    try {
        python $syncScript
        Write-OK 'Agent 配置已同步'
    } catch {
        Write-Warn "同步失败（可稍后手动执行）: $_"
    }
} else {
    Write-Warn 'sync_agent_config.py 不存在，跳过同步'
}

# ══ 完成 ══
Write-Host @"

╔══════════════════════════════════════════════════════╗
║   初始化完成！                                       ║
╠══════════════════════════════════════════════════════╣
║                                                      ║
║  启动看板:                                           ║
║    python dashboard\server.py                        ║
║                                                      ║
║  访问地址:                                           ║
║    http://127.0.0.1:7891                             ║
║                                                      ║
║  启动 Gateway:                                       ║
║    openclaw gateway start                            ║
║                                                      ║
╚══════════════════════════════════════════════════════╝

"@ -ForegroundColor Green
