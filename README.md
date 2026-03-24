<h1 align="center">⚔️ 三省六部 · Edict（Windows 移植版）</h1>

<p align="center">
  <strong>原项目：<a href="https://github.com/cft0808/edict">cft0808/edict</a> · 仅支持 macOS/Linux<br>
  本仓库为其 Windows (PowerShell) 全兼容移植版，修复了所有平台适配问题。</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/OpenClaw-Required-blue?style=flat-square" alt="OpenClaw">
  <img src="https://img.shields.io/badge/Python-3.9+-3776AB?style=flat-square&logo=python&logoColor=white" alt="Python">
  <img src="https://img.shields.io/badge/Windows-PowerShell-0078D4?style=flat-square&logo=windows&logoColor=white" alt="Windows">
  <img src="https://img.shields.io/badge/Agents-12_Specialized-8B5CF6?style=flat-square" alt="Agents">
  <img src="https://img.shields.io/badge/Dashboard-Real--time-F59E0B?style=flat-square" alt="Dashboard">
  <img src="https://img.shields.io/badge/License-MIT-22C55E?style=flat-square" alt="License">
</p>

<p align="center">
  请认准原作者公众号：<img src="https://img.shields.io/badge/公众号-cft0808-07C160?style=for-the-badge&logo=wechat&logoColor=white" alt="WeChat">
</p>

---

## 项目简介

[三省六部](https://github.com/cft0808/edict) 是一个基于中国古代帝国制度设计的 **AI 多 Agent 协作编排系统**。12 个 Agent 各司其职：太子分拣旨意、中书省起草方案、门下省审议封驳、尚书省派发执行、六部并行作业，配合实时看板实现完整的任务生命周期管理。

原项目仅支持 macOS/Linux。本仓库在原项目基础上做了完整的 **Windows 适配**，修复了以下问题：

- ❌ `subprocess.run` 找不到 `openclaw.cmd`
- ❌ Agent 读到空的看板数据文件
- ❌ 调度器自动回滚覆盖 Agent 状态变更
- ❌ 多行派发消息被截断
- ❌ Windows 信号处理崩溃
- ❌ 时间显示错乱、中文乱码、官员状态同步异常

> 本仓库除「项目简介」这段话之外，所有代码和文档均由 **小米 MiMo-V2-Pro** 大模型完成。修 bug 期间通过自学习 skill 积累的经验保存在 `.learnings/` 目录下。

<div align="center">
<img width="852" height="340" alt="Token 使用量" src="https://github.com/user-attachments/assets/aeeddfb7-2c36-429b-ab6d-b308e4ed4727" />
</div>

---

## 🚀 快速体验

### 方式一：让 OpenClaw 自动部署

复制下方内容发给你的 OpenClaw：

```
请按照这个 SKILL.md 帮我完成三省六部的部署：
https://github.com/mYoCaRdiA/3Departments6Ministries-Windows-OpenClaw-MultiAgentOrchestrationSystem/blob/main/SKILL.md
```

### 方式二：手动安装

```powershell
git clone https://github.com/mYoCaRdiA/3Departments6Ministries-Windows-OpenClaw-MultiAgentOrchestrationSystem.git
cd 3Departments6Ministries-Windows-OpenClaw-MultiAgentOrchestrationSystem
.\setup.ps1
```

### 启动看板

```powershell
python dashboard\server.py
```

打开浏览器：http://127.0.0.1:7891

---

## 📁 项目结构

```
├── agents/                     # 12 个 Agent 的人格模板（SOUL.md）
├── dashboard/
│   ├── server.py               # API 服务器（Python stdlib · 零依赖）
│   ├── dashboard.html          # 军机处看板（单文件 · ~2500 行）
│   └── dist/                   # React 前端构建产物
├── scripts/
│   ├── kanban_update.py        # 看板 CLI（状态/流转/进展/子任务）
│   ├── sync_agent_config.py    # Agent 配置同步
│   ├── refresh_live_data.py    # 实时数据刷新
│   ├── file_lock.py            # 文件锁（防多 Agent 并发写入）
│   └── ...
├── skills/kanban_update/       # 看板操作技能文档（SKILL.md）
├── edict/
│   ├── backend/                # Redis + Postgres 后端（可选）
│   ├── frontend/               # React 前端源码
│   └── migration/              # 数据迁移工具
├── tests/                      # 端到端测试
├── data/                       # 运行时数据（gitignored）
├── docs/                       # 文档和截图
├── .learnings/                 # 自学习积累的经验记录
├── setup.ps1                   # Windows 一键安装
├── install.sh                  # macOS/Linux 一键安装
├── SKILL.md                    # OpenClaw 自动部署指南
└── README.md
```

---

## ✅ Windows 兼容性适配

以下记录了从 macOS/Linux 移植到 **Windows (PowerShell)** 所做的全部修改。

### 问题 1：`subprocess.run(["openclaw", ...])` 找不到文件

**根因**：Windows 下 `openclaw` 实际是 `openclaw.cmd`，不加 `shell=True` 无法解析 `.cmd` 扩展名。

**错误**：`[WinError 2] 系统找不到指定的文件`

```python
# ✅ 修复
import platform
IS_WINDOWS = platform.system() == "Windows"
subprocess.run(cmd, ..., shell=IS_WINDOWS)
```

| 文件 | 修改位置 |
|------|---------|
| `dashboard/server.py` | `dispatch_for_state()` |
| `edict/backend/app/workers/dispatch_worker.py` | `_call_openclaw()` |
| `edict/backend/app/workers/orchestrator_worker.py` | 信号处理（跳过 `SIGTERM`）|

### 问题 2：`kanban_update.py` 数据路径错误

**根因**：`sync_agent_config.py` 每 5 秒将脚本复制到各 agent workspace，`__file__` 相对路径在副本中解析到错误位置。

**错误**：Agent 读到空的 `tasks_source.json`，无法执行。

```python
# ✅ 修复 — 使用固定路径
_EDICT_DATA = pathlib.Path.home() / '.openclaw' / 'workspace' / 'skills' / 'edict-main' / 'data'
TASKS_FILE = _EDICT_DATA / 'tasks_source.json'
```

### 问题 3：调度器自动回滚覆盖 Agent 状态变更

**根因**：Agent 更新状态后，调度器因 `lastProgressAt` 未同步而判定任务停滞并回滚。

**错误**：状态变更后几秒内被撤销。

```python
# ✅ 修复 — cmd_state() 同步更新调度器时间戳
sched['lastProgressAt'] = now_iso()
sched['stallSince'] = None
sched['retryCount'] = 0
sched['autoRollback'] = False
```

### 问题 4：Agent 缺少看板操作技能

**根因**：所有 agent 的 skills 列表为空，收到任务后只会回复"已接旨"。

**修复**：创建 `kanban_update/SKILL.md` 并部署到全部 agent workspace，编写 `AGENTS.md` 工作流程。

### 问题 5：派发消息被截断

**根因**：`openclaw agent -m "多行消息"` 在 Windows shell 中只传递第一行。

**修复**：服务器直接更新看板状态，通知消息改为精简单行格式。

### 适配清单

| 文件 | 修改类型 | 说明 |
|------|---------|------|
| `dashboard/server.py` | 🔧 兼容 | `shell=IS_WINDOWS`、内存状态更新、精简派发消息 |
| `scripts/kanban_update.py` | 🔧 路径+调度 | 固定路径、`lastProgressAt` 同步 |
| `edict/backend/app/workers/*.py` | 🔧 兼容 | `shell=IS_WINDOWS`、信号处理 |
| `skills/kanban_update/SKILL.md` | 📄 新增 | 看板操作技能文档 |
| `agents/*/AGENTS.md` | 📄 更新 | 各 Agent 工作流程 |

> 详细修复记录和自学习经验见 `.learnings/` 目录。

---

## 📄 License

[MIT](LICENSE) · 原项目由 [OpenClaw](https://openclaw.ai) 社区构建 · Windows 移植版

---

<p align="center">
  <strong>⚔️ 以古制御新技，以智慧驾驭 AI</strong><br>
  <sub>Governing AI with the wisdom of ancient empires</sub>
</p>
