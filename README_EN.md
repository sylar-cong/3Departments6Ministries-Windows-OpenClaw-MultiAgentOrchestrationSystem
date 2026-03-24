<h1 align="center">⚔️ Edict · Three Departments & Six Ministries (Windows Port)</h1>

<p align="center">
  <strong>Original: <a href="https://github.com/cft0808/edict">cft0808/edict</a> · macOS/Linux only<br>
  This is a fully working Windows (PowerShell) port with all platform issues resolved.</strong>
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
  <a href="README.md">中文</a>
</p>

---

## What is this?

[Edict](https://github.com/cft0808/edict) is an **AI multi-agent orchestration system** modeled after China's 1,300-year-old imperial governance. 12 specialized agents collaborate through a structured workflow:

```
You (Emperor) → Crown Prince (triage) → Planning Dept → Review Dept → Dispatch → Ministries → Done
```

The original project only runs on macOS/Linux. This port makes it fully functional on **Windows with PowerShell**, fixing all platform compatibility issues:

- ❌ `subprocess.run` can't find `openclaw.cmd`
- ❌ Agents read empty kanban data files
- ❌ Scheduler auto-rollback overwrites agent state changes
- ❌ Multi-line dispatch messages get truncated
- ❌ Windows signal handling crashes
- ❌ Time display, encoding, and status sync bugs

> All code and documentation (except this paragraph) was produced by **Xiaomi MiMo-V2-Pro**. Lessons learned during debugging are saved in `.learnings/`.

---

## 🚀 Quick Start

### Option A: Let OpenClaw install it for you

Send this to your OpenClaw instance:

```
Please deploy Edict using this SKILL.md:
https://github.com/mYoCaRdiA/3Departments6Ministries-Windows-OpenClaw-MultiAgentOrchestrationSystem/blob/main/SKILL.md
```

### Option B: Manual install

```powershell
git clone https://github.com/mYoCaRdiA/3Departments6Ministries-Windows-OpenClaw-MultiAgentOrchestrationSystem.git
cd 3Departments6Ministries-Windows-OpenClaw-MultiAgentOrchestrationSystem
.\setup.ps1
```

### Start the dashboard

```powershell
python dashboard\server.py
```

Open browser: http://127.0.0.1:7891

---

## 📁 Project Structure

```
├── agents/                     # 12 Agent persona templates (SOUL.md)
├── dashboard/
│   ├── server.py               # API server (Python stdlib · zero deps)
│   ├── dashboard.html          # Real-time kanban dashboard (~2500 lines)
│   └── dist/                   # React frontend build output
├── scripts/
│   ├── kanban_update.py        # Kanban CLI (state/flow/progress/todos)
│   ├── sync_agent_config.py    # Agent config sync
│   ├── refresh_live_data.py    # Live data refresh
│   ├── file_lock.py            # File locking for concurrent writes
│   └── ...
├── skills/kanban_update/       # Kanban skill documentation (SKILL.md)
├── edict/
│   ├── backend/                # Redis + Postgres backend (optional)
│   ├── frontend/               # React frontend source
│   └── migration/              # Data migration tools
├── tests/                      # End-to-end tests
├── data/                       # Runtime data (gitignored)
├── docs/                       # Documentation and screenshots
├── .learnings/                 # Self-learned debugging knowledge
├── setup.ps1                   # Windows one-click setup
├── install.sh                  # macOS/Linux one-click setup
├── SKILL.md                    # OpenClaw auto-deploy guide
└── README.md
```

---

## ✅ Windows Compatibility Fixes

All changes made to port from macOS/Linux to **Windows (PowerShell)**.

### Issue 1: `subprocess.run(["openclaw", ...])` file not found

**Root cause**: On Windows, `openclaw` is installed as `openclaw.cmd`. Without `shell=True`, `subprocess.run` can't resolve `.cmd` extensions.

**Error**: `[WinError 2] The system cannot find the file specified`

```python
# ✅ Fix
import platform
IS_WINDOWS = platform.system() == "Windows"
subprocess.run(cmd, ..., shell=IS_WINDOWS)
```

| File | Location |
|------|----------|
| `dashboard/server.py` | `dispatch_for_state()` |
| `edict/backend/app/workers/dispatch_worker.py` | `_call_openclaw()` |
| `edict/backend/app/workers/orchestrator_worker.py` | Signal handling (skip `SIGTERM`) |

### Issue 2: `kanban_update.py` data path error

**Root cause**: `sync_agent_config.py` copies the script to each agent workspace every 5 seconds. The `__file__`-relative path resolves differently in each copy, pointing to empty data files.

**Error**: Agent reads empty `tasks_source.json`, can't execute tasks.

```python
# ✅ Fix — use absolute path
_EDICT_DATA = pathlib.Path.home() / '.openclaw' / 'workspace' / 'skills' / 'edict-main' / 'data'
TASKS_FILE = _EDICT_DATA / 'tasks_source.json'
```

### Issue 3: Scheduler auto-rollback overwrites agent state

**Root cause**: After an agent updates task state, the scheduler's periodic scan detects `lastProgressAt` is stale and reverts the change.

**Error**: State changes are silently rolled back within seconds.

```python
# ✅ Fix — cmd_state() syncs scheduler timestamps
sched['lastProgressAt'] = now_iso()
sched['stallSince'] = None
sched['retryCount'] = 0
sched['autoRollback'] = False
```

### Issue 4: Agents lack kanban operation skills

**Root cause**: All agents have empty skill lists. They receive dispatch messages but don't know how to read/write kanban data.

**Fix**: Deploy `kanban_update/SKILL.md` to all agent workspaces. Write `AGENTS.md` workflow docs with executable commands.

### Issue 5: Dispatch messages get truncated

**Root cause**: `openclaw agent -m "multi-line message"` only delivers the first line on Windows shell.

**Fix**: Server updates kanban state directly, sends concise single-line notifications to agents.

### Fix Summary

| File | Type | Changes |
|------|------|---------|
| `dashboard/server.py` | 🔧 Compat | `shell=IS_WINDOWS`, in-memory state update, concise dispatch |
| `scripts/kanban_update.py` | 🔧 Path+Scheduler | Absolute path, `lastProgressAt` sync |
| `edict/backend/app/workers/*.py` | 🔧 Compat | `shell=IS_WINDOWS`, signal handling |
| `skills/kanban_update/SKILL.md` | 📄 New | Kanban skill documentation |
| `agents/*/AGENTS.md` | 📄 Updated | Agent workflow docs |

> Detailed debugging logs and self-learned knowledge in `.learnings/`.

---

## 📄 License

[MIT](LICENSE) · Original by [OpenClaw](https://openclaw.ai) community · Windows port

---

<p align="center">
  <strong>⚔️ Governing AI with the wisdom of ancient empires</strong>
</p>
