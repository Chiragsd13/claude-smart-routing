# Claude Smart Routing

Designed by [@Chiragsd13](https://github.com/Chiragsd13)

---

## The Problem This Solves

Claude is arguably more capable than ChatGPT and Gemini for complex coding tasks. But it has one major weakness that holds it back in real-world use: **token exhaustion**.

Context windows fill up. Long sessions hit limits. Multi-file projects burn through tokens fast. And the default behavior makes it worse: Claude uses the same heavy model for a typo fix as it does for a full architecture redesign. It scans every file even when it only needs one. Multiple agents doing the same work redundantly.

This config fixes that. It makes Claude smarter about when and how to spend tokens.

---

## Token Efficiency Gains

Based on typical usage patterns, this config makes your token use approximately **40 to 60% more efficient**. Here is how:

### From model routing

About 40% of dev tasks are trivial (typo fixes, renames, small edits, quick questions). By default these run on Sonnet. Haiku handles them at roughly 1/8 the cost.

```
40% of tasks at 1/8 the cost = ~30% overall token savings from routing alone
```

### From the codemap combo

Without codemaps, every agent in a multi-agent run scans the raw codebase independently.

```
Without map:  3 agents x ~3000 tokens scanning = 9000 tokens on context loading
With map:     3 agents x ~800 tokens reading map = 2400 tokens on context loading

Savings: 73% reduction in context loading for large projects
```

### From smart multi-model usage

Instead of asking Claude the same question 2 or 3 times to refine an answer, one multi-model run gives you 3 perspectives at once. Same or lower total cost, better output on the first try.

**Combined result: roughly 40 to 60% fewer tokens spent per session, with higher quality output.**

---

## What It Does

### Tier 1: Model Routing

Claude auto-selects the right model instead of defaulting to Sonnet for everything:

| Task | Model | Why |
|------|-------|-----|
| Typo fix, rename, quick question | Inline (no agent) | Zero overhead, just do it |
| Small edits across files, formatting, boilerplate | Haiku 4.5 | ~8x cheaper than Sonnet |
| Bug fixes, features, code review, refactoring | Sonnet 4.6 | Best coding model |
| Architecture, security, system design | Opus 4.6 | Deepest reasoning |
| Multi-domain or full-stack | Multi-model | Parallel agents, fastest and best quality |

Sub-agents within any task default to Haiku workers with Sonnet as orchestrator.

---

### Tier 2: Smart Multi-Model Parallelism

Powered by [ccg-workflow](https://www.npmjs.com/package/ccg-workflow). Claude, Codex, and Gemini run simultaneously on different parts of the same task.

Only fires when it is worth it:
- Complex features, architecture decisions, full-stack work
- Ambiguous requirements where multiple perspectives help
- Quality matters more than token cost

Skipped automatically for simple fixes, renames, small edits, and quick questions.

```
/multi-plan      planning phase, all 3 models in parallel
/multi-frontend  Gemini leads UI, others review
/multi-backend   Codex leads logic, others review
/multi-workflow  full feature, complete parallel pipeline
/multi-execute   parallel subtask execution
/ccg:analyze     all 3 models give opinions, synthesized output
```

---

### Tier 3: Large Project Combo (Map, Identify, Target, Execute)

Auto-triggers for full-stack projects, large codebases, monorepos, or projects with more than 20 files or directories.

```
Step 1: /update-codemaps
        Scans the whole project once and writes token-lean docs to docs/CODEMAPS/
        architecture.md   system diagram and service boundaries
        backend.md        API routes, services, repos
        frontend.md       page tree, component hierarchy
        data.md           DB tables and relationships
        dependencies.md   external services and integrations
        Each file is about 800 tokens. Total map is about 4000 tokens.

Step 2: Read map to identify relevant files
        Agents read docs/CODEMAPS/ to figure out exactly which files touch the task.
        No raw files opened yet. Just the map.

Step 3: Open only the targeted raw files
        Agents open and read only the specific files the map pointed to.
        Everything else is ignored. No full codebase scan.

Step 4: /multi-* for parallel execution
        Claude, Codex, and Gemini work in parallel on the targeted files only.
```

The map acts as a smart index. Agents use it to navigate and identify what matters, then go straight to those raw files instead of reading everything.

---

### Tier 4: Context Budget and Session Handoff

**Context budget:** when context hits 95%, Claude stops, summarizes progress and the exact next step, then runs /save-session before the window fills. On resuming, /resume-session reloads state so work continues from where it left off instead of restarting.

This matters because token exhaustion mid-task is worse than hitting the limit at a clean stopping point. 95% gives just enough room to write the summary without cutting off.

**Session handoff:** at the end of any long or multi-step task, /save-session persists state automatically. If a session drops unexpectedly, /resume-session picks it back up.

---

### Tier 5: Writing Work Auto-Humanizer

Auto-triggers for any writing that gets submitted or posted: school assignments, essays, reports, emails, cover letters, social posts, anything a human will read.

The problem: AI writing is detectable. It overuses certain words (pivotal, showcase, delve, foster), structures every paragraph the same way, adds fake significance to ordinary things, and reads like it was assembled rather than written.

The fix: after generating any writing work, the [humanizer skill](https://github.com/blader/humanizer) runs automatically on the output before it is delivered.

What it does:
- Strips AI vocabulary (pivotal, testament, underscores, vibrant, groundbreaking)
- Removes promotional and inflated language
- Fixes passive voice and subjectless fragments
- Removes em dash overuse, excessive bolding, rule of three patterns
- Removes sycophantic openers (Great question! Certainly! I hope this helps!)
- Adds natural rhythm and actual voice so it reads like a person wrote it
- Does a final pass asking "what still makes this obviously AI?" and fixes those too

```
You: "write my essay on climate policy"
Claude writes the essay, then /humanizer runs automatically.
Output sounds like you wrote it, not like a language model.
```

---

## Skills and Repos Combined

This config mindfully combines the following. It is not derived from or built on any of them:

| Tool | Source | Role in this config |
|------|--------|---------------------|
| Everything Claude Code (ECC) | [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code) | ccg commands, agents, rules, skills, the full harness |
| update-codemaps | [ECC commands/update-codemaps.md](https://github.com/affaan-m/everything-claude-code/blob/main/commands/update-codemaps.md) | Scans project, generates token-lean architecture maps in docs/CODEMAPS/ |
| multi-* commands | [ECC commands/](https://github.com/affaan-m/everything-claude-code/tree/main/commands) | multi-plan, multi-frontend, multi-backend, multi-workflow, multi-execute |
| humanizer | [blader/humanizer](https://github.com/blader/humanizer) | Removes AI writing patterns, adds natural voice, makes writing sound human |
| ccg-workflow runtime | [npm: ccg-workflow](https://www.npmjs.com/package/ccg-workflow) | Installs codeagent-wrapper and Claude/Codex/Gemini prompt sets, powers parallel execution |
| Claude (Haiku, Sonnet, Opus) | [Anthropic](https://anthropic.com) | Tiered model selection based on task complexity |
| Codex | [OpenAI](https://openai.com/blog/openai-codex) | Backend-focused model in multi-agent runs |
| Gemini | [Google DeepMind](https://deepmind.google/technologies/gemini/) | Frontend-focused model in multi-agent runs |

---

## Setup

### Prerequisites

1. Install [Everything Claude Code](https://github.com/affaan-m/everything-claude-code):
   ```bash
   git clone https://github.com/affaan-m/everything-claude-code.git
   cd everything-claude-code
   npm install
   ```

2. Initialize the ccg-workflow runtime:
   ```bash
   npx ccg-workflow
   ```
   This installs `~/.claude/bin/codeagent-wrapper` and `~/.claude/.ccg/prompts/` with claude, codex, and gemini prompt sets.

3. Add `Bash(*codeagent-wrapper*)` to your `~/.claude/settings.json` allow list:
   ```json
   {
     "permissions": {
       "allow": ["Bash(*codeagent-wrapper*)"]
     }
   }
   ```

### Install the config

Copy CLAUDE.md to your global Claude config directory:

```bash
cp CLAUDE.md ~/.claude/CLAUDE.md
```

Or merge the relevant sections into your existing `~/.claude/CLAUDE.md`.

---

## How It Looks in Practice

```
You: "fix the typo in auth.ts"
Claude handles it inline. No agent spawn. Zero overhead.

You: "add dark mode support"
Haiku agent. Small distinct task, cheap and fast.

You: "refactor the auth module"
Sonnet. Standard dev work.

You: "redesign the database schema for multi-tenancy"
Opus. Deep reasoning required.

You: "build the full checkout flow"
/multi-workflow fires. Claude + Codex + Gemini in parallel.

You: "add a feature to this large monorepo"
/update-codemaps runs first, shared map is built, then /multi-* agents run
using the map instead of scanning 500 files each.
```

---

## Credits

Designed and configured by [@Chiragsd13](https://github.com/Chiragsd13).

This config mindfully combines independently developed tools. It is not derived from or built on any of them:

- [Everything Claude Code](https://github.com/affaan-m/everything-claude-code) by [@affaan-m](https://github.com/affaan-m)
- [update-codemaps](https://github.com/affaan-m/everything-claude-code/blob/main/commands/update-codemaps.md) part of ECC
- [humanizer](https://github.com/blader/humanizer) by [@blader](https://github.com/blader)
- [ccg-workflow](https://www.npmjs.com/package/ccg-workflow) multi-model runtime by CCG Contributors
- [Claude](https://anthropic.com) by Anthropic
- [Codex](https://openai.com/blog/openai-codex) by OpenAI
- [Gemini](https://deepmind.google/technologies/gemini/) by Google DeepMind
