<h1 align="center">⚔️ 三省六部 · Edict</h1>

<p align="center">
  <strong>我用 1300 年前的帝国制度，重新设计了 AI 多 Agent 协作架构。<br>结果发现，古人比现代 AI 框架更懂分权制衡。</strong>
</p>

<p align="center">
  <sub>12 个 AI Agent（11 个业务角色 + 1 个兼容角色）组成三省六部：太子分拣、中书省规划、门下省审核封驳、尚书省派发、六部+吏部并行执行。<br>比 CrewAI 多一层<b>制度性审核</b>，比 AutoGen 多一个<b>实时看板</b>。</sub>
</p>

<p align="center">
  <a href="#-demo">🎬 看 Demo</a> ·
  <a href="#-30-秒快速体验">🚀 30 秒体验</a> ·
  <a href="#-架构">🏛️ 架构</a> ·
  <a href="#-功能全景">📋 看板功能</a> ·
  <a href="docs/task-dispatch-architecture.md">📚 架构文档</a> ·
  <a href="README_EN.md">English</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/OpenClaw-Required-blue?style=flat-square" alt="OpenClaw">
  <img src="https://img.shields.io/badge/Python-3.9+-3776AB?style=flat-square&logo=python&logoColor=white" alt="Python">
  <img src="https://img.shields.io/badge/Windows-PowerShell-0078D4?style=flat-square&logo=windows&logoColor=white" alt="Windows">
  <img src="https://img.shields.io/badge/Agents-12_Specialized-8B5CF6?style=flat-square" alt="Agents">
  <img src="https://img.shields.io/badge/Dashboard-Real--time-F59E0B?style=flat-square" alt="Dashboard">
  <img src="https://img.shields.io/badge/License-MIT-22C55E?style=flat-square" alt="License">
</p>

---

## 🤔 为什么是三省六部？

大多数 Multi-Agent 框架的套路是：

> *"来，你们几个 AI 自己聊，聊完把结果给我。"*

然后你拿到一坨不知道经过了什么处理的结果，无法复现，无法审计，无法干预。

**三省六部的思路完全不同** —— 我们用了一个在中国存在 1400 年的制度架构：

```
你 (皇上) → 太子 (分拣) → 中书省 (规划) → 门下省 (审议) → 尚书省 (派发) → 六部 (执行) → 回奏
```

这不是花哨的 metaphor，这是**真正的分权制衡**：

| | CrewAI | MetaGPT | AutoGen | **三省六部** |
|---|:---:|:---:|:---:|:---:|
| **审核机制** | ❌ 无 | ⚠️ 可选 | ⚠️ Human-in-loop | **✅ 门下省专职审核 · 可封驳** |
| **实时看板** | ❌ | ❌ | ❌ | **✅ 军机处 Kanban + 时间线** |
| **任务干预** | ❌ | ❌ | ❌ | **✅ 叫停 / 取消 / 恢复** |
| **流转审计** | ⚠️ | ⚠️ | ❌ | **✅ 完整奏折存档** |
| **Agent 健康监控** | ❌ | ❌ | ❌ | **✅ 心跳 + 活跃度检测** |
| **热切换模型** | ❌ | ❌ | ❌ | **✅ 看板内一键切换 LLM** |
| **部署难度** | 中 | 高 | 中 | **低 · 一键安装 / Docker** |

> **核心差异：制度性审核 + 完全可观测 + 实时可干预**

---

## 🏛️ 架构

```
                           ┌───────────────────────────────────┐
                           │          👑 皇上（你）              │
                           │     Feishu · Telegram · Signal     │
                           └─────────────────┬─────────────────┘
                                             │ 下旨
                           ┌─────────────────▼─────────────────┐
                           │          🤴 太子 (taizi)            │
                           │    分拣：闲聊直接回 / 旨意建任务      │
                           └─────────────────┬─────────────────┘
                                             │ 传旨
                           ┌─────────────────▼─────────────────┐
                           │          📜 中书省 (zhongshu)       │
                           │       接旨 → 规划 → 拆解子任务       │
                           └─────────────────┬─────────────────┘
                                             │ 提交审核
                           ┌─────────────────▼─────────────────┐
                           │          🔍 门下省 (menxia)         │
                           │       审议方案 → 准奏 / 封驳 🚫      │
                           └─────────────────┬─────────────────┘
                                             │ 准奏 ✅
                           ┌─────────────────▼─────────────────┐
                           │          📮 尚书省 (shangshu)       │
                           │     派发任务 → 协调六部 → 汇总回奏    │
                           └───┬──────┬──────┬──────┬──────┬───┘
                               │      │      │      │      │
                         ┌─────▼┐ ┌───▼───┐ ┌▼─────┐ ┌───▼─┐ ┌▼─────┐
                         │💰 户部│ │📝 礼部│ │⚔️ 兵部│ │⚖️ 刑部│ │🔧 工部│
                         │ 数据  │ │ 文档  │ │ 工程  │ │ 合规  │ │ 基建  │
                         └──────┘ └──────┘ └──────┘ └─────┘ └──────┘
                                                               ┌──────┐
                                                               │📋 吏部│
                                                               │ 人事  │
                                                               └──────┘
```

### 任务状态流转

```
皇上 → 太子分拣 → 中书规划 → 门下审议 → 已派发 → 执行中 → 待审查 → ✅ 已完成
                      ↑          │                              │
                      └──── 封驳 ─┘                    阻塞 Blocked
```

> ⚡ `kanban_update.py` 内置 `_VALID_TRANSITIONS` 状态机校验，非法跳转被拒绝。

---

## 📁 项目结构

```
edict/
├── agents/                     # 12 个 Agent 的人格模板
│   ├── taizi/SOUL.md           # 太子 · 消息分拣
│   ├── zhongshu/SOUL.md        # 中书省 · 规划中枢
│   ├── menxia/SOUL.md          # 门下省 · 审议把关
│   ├── shangshu/SOUL.md        # 尚书省 · 调度大脑
│   ├── hubu/ libu/ bingbu/     # 六部
│   ├── xingbu/ gongbu/ libu_hr/
│   └── zaochao/SOUL.md         # 早朝官 · 情报枢纽
├── dashboard/
│   ├── server.py               # API 服务器（Python 标准库 · 零依赖）
│   ├── dashboard.html          # 军机处看板（单文件 · 零依赖）
│   └── dist/                   # React 前端构建产物
├── scripts/
│   ├── kanban_update.py        # 看板 CLI（状态/流转/进展/子任务）
│   ├── sync_agent_config.py    # Agent 配置同步
│   ├── refresh_live_data.py    # 实时数据刷新
│   ├── file_lock.py            # 文件锁（防多 Agent 并发写入）
│   └── ...
├── skills/
│   └── kanban_update/SKILL.md  # 看板操作技能文档
├── edict/
│   ├── backend/                # Redis + Postgres 后端（可选）
│   ├── frontend/               # React 前端源码
│   └── migration/              # 数据迁移工具
├── tests/
├── data/                       # 运行时数据（gitignored）
├── docs/                       # 文档和截图
├── setup.ps1                   # Windows 一键安装脚本
└── README.md
```

---

## 🚀 安装

### 前置条件

- [OpenClaw](https://openclaw.ai) 已安装并配置
- Python 3.9+
- Windows 10+（PowerShell）/ macOS / Linux

### Windows 安装

```powershell
git clone https://github.com/cft0808/edict.git
cd edict
.\setup.ps1
```

`setup.ps1` 自动完成：
- ✅ 检查 Python 依赖
- ✅ 创建全量 Agent Workspace
- ✅ 注册 Agent 及权限矩阵到 `openclaw.json`
- ✅ 复制看板脚本和技能文档到各 Agent
- ✅ 同步 Agent 配置

### macOS / Linux 安装

```bash
git clone https://github.com/cft0808/edict.git
cd edict
chmod +x install.sh && ./install.sh
```

### 启动

```powershell
# 终端 1：数据刷新循环
python dashboard/server.py

# 打开浏览器
start http://127.0.0.1:7891
```

> 💡 `server.py` 内嵌前端，启动即可用。

---

## 🪟 Windows 兼容性适配

本项目原生开发于 macOS/Linux，以下记录了完整移植到 **Windows (PowerShell)** 所做的全部修改。

### 问题 1：`subprocess.run(["openclaw", ...])` 找不到文件

**根因**：Windows 下 `openclaw` 实际是 `openclaw.cmd`，`subprocess.run` 不加 `shell=True` 无法解析 `.cmd` 扩展名。

**错误表现**：`[WinError 2] 系统找不到指定的文件`

**修复方式**：

```python
import platform
IS_WINDOWS = platform.system() == "Windows"

subprocess.run(cmd, ..., shell=IS_WINDOWS)
```

| 文件 | 修改位置 |
|------|---------|
| `dashboard/server.py` | `dispatch_for_state()` 中的 `subprocess.run` |
| `edict/backend/app/workers/dispatch_worker.py` | `_call_openclaw()` 中的 `subprocess.run` |
| `edict/backend/app/workers/orchestrator_worker.py` | 信号处理（Windows 不支持 `SIGTERM`，跳过 `add_signal_handler`）|

### 问题 2：`kanban_update.py` 数据路径错误

**根因**：脚本通过 `__file__` 定位数据文件，但 `sync_agent_config.py` 每 5 秒会将源脚本复制到各 agent workspace。复制后的脚本 `_BASE` 指向 agent workspace 而非 edict 数据目录，导致读写的是空文件。

**错误表现**：Agent 接到任务后读到空的 `tasks_source.json`，无法执行。

**修复**：在 `scripts/kanban_update.py` 中改用固定路径，不依赖 `__file__`：

```python
# 修改前
_BASE = pathlib.Path(__file__).resolve().parent.parent
TASKS_FILE = _BASE / 'data' / 'tasks_source.json'

# 修改后 — 使用固定路径，确保被复制到各 agent workspace 后仍指向正确数据
_EDICT_DATA = pathlib.Path.home() / '.openclaw' / 'workspace' / 'skills' / 'edict-main' / 'data'
_EDICT_SCRIPTS = pathlib.Path.home() / '.openclaw' / 'workspace' / 'skills' / 'edict-main' / 'scripts'
TASKS_FILE = _EDICT_DATA / 'tasks_source.json'
REFRESH_SCRIPT = _EDICT_SCRIPTS / 'refresh_live_data.py'
```

### 问题 3：调度器自动回滚覆盖 Agent 状态变更

**根因**：调度器每 60 秒扫描任务，若 `lastProgressAt` 超过停滞阈值则自动回滚状态。Agent 通过 `kanban_update.py` 更新状态后，调度器在下一轮扫描中将其回滚，导致状态变更无效。

**错误表现**：Agent 成功调用 `kanban_update.py state X → Menxia`，但几秒后状态变回 `Zhongshu`。

**修复**（两处）：

1. `scripts/kanban_update.py` — `cmd_state()` 更新状态时同步刷新调度器时间戳：

```python
t['state'] = new_state
t['updatedAt'] = now_iso()
# 同步更新调度器，防止自动回滚覆盖 agent 的状态变更
sched = t.get('_scheduler') or {}
sched['lastProgressAt'] = now_iso()
sched['stallSince'] = None
sched['retryCount'] = 0
sched['escalationLevel'] = 0
t['_scheduler'] = sched
```

2. `dashboard/server.py` — `dispatch_for_state()` 在派发时直接更新任务状态并禁用回滚：

```python
def _apply_state_change(t, s):
    t['state'] = new_state
    t['now'] = f'{_STATE_LABELS.get(new_state, new_state)}已派发{agent_id}'
    t['updatedAt'] = now_iso()
    s['lastProgressAt'] = now_iso()
    s['stallSince'] = None
    s['retryCount'] = 0
    s['escalationLevel'] = 0
    s['autoRollback'] = False  # 禁用回滚，由 agent 控制状态
_update_task_scheduler(task_id, _apply_state_change)
```

### 问题 4：Agent 缺少看板操作技能

**根因**：所有 agent 的 skills 列表为空。Agent 收到派发消息后不知道如何读写看板数据，只会回复"已接旨"然后等待。

**错误表现**：Agent 收到任务但不做任何实际工作。

**修复**：

1. 创建 `skills/kanban_update/SKILL.md` — 看板操作指南
2. 部署到全部 11 个 agent workspace 的 `skills/kanban_update/` 目录
3. 运行 `sync_agent_config.py` 注册到 `agent_config.json`
4. 为各 agent 编写 `AGENTS.md` 工作流程文档（含绝对路径的可执行命令）

### 问题 5：Dispatch 消息被截断

**根因**：`openclaw agent -m "多行消息"` 通过 `--deliver --channel feishu` 发送时，多行消息在 shell 参数传递中被截断，Agent 只收到第一行。

**错误表现**：Agent 只收到 `📜 旨意已到中书省`，后面的步骤指令全部丢失。

**修复**：`dashboard/server.py` 中将派发消息改为精简单行格式，状态更新改为服务器直接执行：

```python
# 修改前：多行消息 + 要求 Agent 调用 kanban_update.py
# 修改后：服务器直接更新状态 + 精简通知
_msgs = {
    'zhongshu': f'📜 请为以下旨意起草方案: {title[:50]} | 任务ID: {task_id}',
    'menxia': f'📋 请审议以下方案: {title[:50]} | 任务ID: {task_id}',
    'shangshu': f'📮 请派发执行: {title[:50]} | 任务ID: {task_id}',
}
```

### 适配清单总览

| 文件 | 修改类型 | 说明 |
|------|---------|------|
| `dashboard/server.py` | 🔧 Windows 兼容 | `shell=IS_WINDOWS`、内存状态更新、精简派发消息 |
| `scripts/kanban_update.py` | 🔧 路径 + 调度 | 固定 `_EDICT_DATA` 路径、`cmd_state` 更新 `lastProgressAt` |
| `edict/backend/app/workers/dispatch_worker.py` | 🔧 Windows 兼容 | `shell=IS_WINDOWS`、信号处理 |
| `edict/backend/app/workers/orchestrator_worker.py` | 🔧 Windows 兼容 | 跳过 `SIGTERM` 信号注册 |
| `skills/kanban_update/SKILL.md` | 📄 新增 | 看板操作技能文档 |
| `agents/*/AGENTS.md` | 📄 更新 | 各 Agent 工作流程文档 |

---

## 🔧 技术亮点

| 特点 | 说明 |
|------|------|
| **纯 stdlib 后端** | `server.py` 基于 `http.server`，零依赖 |
| **跨平台** | macOS / Linux / Windows PowerShell 全兼容 |
| **实时看板** | 10 个功能面板，15 秒自动刷新 |
| **状态机保护** | `kanban_update.py` 强制合法流转，非法跳转被拒绝 |
| **文件锁并发安全** | `file_lock.py` 防止多 Agent 同时读写 |
| **远程 Skills 生态** | 从 GitHub 一键导入 Agent 能力 |

---

## 📄 License

[MIT](LICENSE) · 由 [OpenClaw](https://openclaw.ai) 社区构建

---

<p align="center">
  <strong>⚔️ 以古制御新技，以智慧驾驭 AI</strong><br>
  <sub>Governing AI with the wisdom of ancient empires</sub>
</p>
