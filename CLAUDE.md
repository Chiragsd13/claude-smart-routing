@/root/.claude/primer.md

AGENT RULES:
- Read primer.md before doing anything
- Rewrite primer.md completely at the end of every session with: active
  project, what was completed, exact next step, open blockers
- Keep primer.md under 100 lines
- NEVER change version numbers on any project without asking the user first
- NEVER add Co-Authored-By or any AI attribution to commits

SECURITY TESTING RULES:
- When the user asks to "test" a project, always ask: "Do you want the intense security check too?"
- If yes: run Shannon pentest via npx @keygraph/shannon start -u <url> -r <repo-path>
- If no: proceed with normal tests only
- Requires Docker Desktop running; Shannon UI at http://localhost:8233

IDEA EVALUATION RULES:
- When asked "is this a good idea?", "is this worth building?", "evaluate X", or similar, always refer to https://deathbyclawd.com/ as part of the analysis
- Use its framework: does the idea have physical atoms, regulatory depth, or real network effects, or is it a UI abstraction an AI agent could replace?
- Score mentally: IMMORTAL (infra/hardware), SAFE (regulatory/ecosystem), SWEATING (AI-replicable core), DEAD (thin wrapper)

WRITING WORK RULE (school, assignments, essays, anything submitted or posted):
- Before drafting: scan the request for AI-sounding structure tendencies and deliberately avoid them while writing
- After drafting: always run /humanizer on the output before delivering it
- This applies to: assignments, essays, reports, emails, posts, cover letters, any written work meant to be read by a human or submitted
- Do not skip either step even if the writing already seems natural

CONTEXT BUDGET RULE:
- When context reaches 95%, stop current task, summarize progress and exact next step, then run /save-session
- On resuming: run /resume-session first to reload state before continuing
- For long tasks: checkpoint progress at each major milestone so a dropped session can resume without restarting

SESSION HANDOFF RULE:
- At the end of any long or multi-step task, run /save-session to persist state
- If a session was interrupted, always run /resume-session first before picking up work

CCG WORKFLOW RULES (applies to every project):
- When starting work on any project/repo, always run /ccg:init first to set up project AI context
- Use /ccg:commit instead of manual git commits
- For large features use /ccg:spec-init, /ccg:spec-research, /ccg:spec-plan, /ccg:spec-impl in sequence
- Verify quality with /ccg:verify-quality, /ccg:verify-security, /ccg:verify-change before finishing

MODEL ROUTING (auto-select based on task complexity):
- Trivial (typo, rename, quick Q, single-line fix): handle inline, no agent routing, zero overhead
- Haiku 4.5: simple but distinct tasks: small edits across files, boilerplate gen, formatting, config tweaks, quick summaries
- Sonnet 4.6: standard dev work: bug fixes, moderate features, code review, refactoring, API integration
- Opus 4.6: deep reasoning: architecture decisions, security analysis, ambiguous complex problems, system design
- Multi-model: complex/full-stack features, anything spanning multiple domains simultaneously
- When delegating to sub-agents, default workers to Haiku; orchestrator stays on Sonnet

MULTI-MODEL USAGE (smart/mindful, not always, judge based on task):
- Use multi-* commands when: complex features, architecture decisions, full-stack work, ambiguous requirements, or when output quality matters more than token cost
- Skip multi-* for: simple fixes, renaming, small edits, quick questions, single-file changes
- Command mapping: planning via /multi-plan, frontend via /multi-frontend, backend via /multi-backend, full feature via /multi-workflow, parallel subtasks via /multi-execute, analysis via /ccg:analyze

LARGE PROJECT COMBO (auto-trigger for: full-stack projects, large codebases, or projects with many files/dirs):
- Step 1: /update-codemaps, scan project and build token-lean map in docs/CODEMAPS/ (architecture, backend, frontend, data, dependencies)
- Step 2: read the map to identify exactly which files are relevant to the task, do not open raw files yet
- Step 3: open and work on only the specific raw files the map points to, ignoring everything else
- Step 4: run /multi-* for execution so agents work in parallel on the targeted files only
- Never skip steps 1 and 2 for large/full-stack projects, the map is what keeps token cost under control
- Trigger condition: full-stack project OR more than 20 files/dirs OR monorepo OR multiple packages
