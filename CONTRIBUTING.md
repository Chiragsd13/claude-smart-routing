# Contributing to Claude Smart Routing

Thanks for your interest in improving this project. Contributions are welcome.

## What This Project Is

Claude Smart Routing is a configuration layer, not a library. Contributions are mostly:
- Improving routing thresholds or model tier logic
- Adding new command mappings
- Fixing documentation or examples
- Reporting edge cases where the routing gives wrong results

## How to Contribute

### Reporting Issues

Open an issue describing:
- What task you were doing
- Which model was selected
- Which model should have been selected and why
- Approximate token cost if known

### Suggesting Routing Changes

If a routing rule is wrong (e.g., a task type that should be Haiku but defaults to Sonnet), open an issue with:
- The task category
- Proposed model tier
- Reasoning (ideally with a cost comparison)

### Submitting Changes

1. Fork the repo
2. Create a branch: `git checkout -b fix/routing-threshold`
3. Make your change in `CLAUDE.md`
4. Test it against at least 3 real tasks of the affected category
5. Open a PR with before/after examples

## Routing Tier Reference

| Tier | Model | When |
|------|-------|------|
| Inline | No agent | Trivial: typo, rename, single line |
| Haiku 4.5 | Lightweight | Small edits, boilerplate, formatting |
| Sonnet 4.6 | Standard | Bug fixes, moderate features, review |
| Opus 4.6 | Deep | Architecture, security, ambiguous complex problems |
| Multi-model | Parallel | Full-stack features, multi-domain |

## Style Guide

- Keep CLAUDE.md under 150 lines where possible
- Use plain language, no jargon
- Every rule should answer: "what triggers this?" and "what does it do?"
- Avoid markdown formatting inside code blocks that run as shell commands

## Questions

Open an issue with the `question` label.
