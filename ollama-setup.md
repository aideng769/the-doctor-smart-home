# Ollama — Native Install Setup

Ollama runs natively on Windows (not in Docker) and is reached by Home Assistant at
`http://host.docker.internal:11434` — Docker Desktop's built-in hostname for reaching the Windows
host from inside a container.

## Install

1. Install Ollama natively on the desktop (Windows): https://ollama.com
2. Pull the model used by both agents below:
ollama pull qwen3:14b

3. In Home Assistant: **Settings → Devices & Services → Add Integration → Ollama**, URL
   `http://host.docker.internal:11434`.

## Two conversation agents, one Ollama integration

This project's Home Assistant version groups multiple agents as **services under one Ollama
integration entry**, not as separate integrations — worth knowing if this screen looks different
than expected.

Add two agent entries under that integration:

| Agent | Model | "Control Home Assistant" tool access | Role |
|---|---|---|---|
| **Device agent** | `qwen3:14b` | **ON** | Original Phase 1 design intent — device/command-oriented, for future sentence-trigger command routing. **Not currently assigned to the Assist pipeline.** |
| **General agent** | `qwen3:14b` | **OFF** | **Currently assigned to the Assist pipeline** — handles all real voice interactions. Tool access is deliberately OFF to avoid tool-calling confusion (see below). |

In **Settings → Voice assistants → Assist**, the pipeline's "Conversation agent" should be set to
the **General agent**, not the Device agent.

## Why tool access is OFF on the active agent

With tool access on, the model would attempt (and sometimes garble) Home Assistant tool calls even
for general conversational queries — producing confused "I don't know the device X" responses to
things that had nothing to do with devices. Splitting into two agents and disabling tool access on
the one actually assigned to voice resolved this.

## Known, accepted limitation — do not "fix"

The General agent has no live/current knowledge (no internet access, no tools): it will give
wrong or outdated answers to date-dependent or current-events questions (confirmed wrong on
things like "has the 2026 World Cup happened," celebrity ages, non-local timezone times). This is
an **accepted, permanent limitation**, not a bug — re-enabling tools to fix it would reintroduce
the original tool-calling confusion. Don't re-enable tool access on the General agent to address
this.