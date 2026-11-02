# cintix-skills

Custom [Claude Code](https://claude.com/claude-code) skills.

## Skills

### `modular-hybrid-architecture`

Design or refactor applications into a modular monolith with feature-module ownership, explicit public contracts, hidden internals, module-owned data and transactions, and explicit cross-module orchestration.

`SKILL.md` is the concise entry point. The detailed rules live in `references/` and are loaded only when relevant:

| Reference | Contents |
|---|---|
| `module-boundaries.md` | module layout, public contracts, shared DTOs, internal module architecture |
| `runtime-and-technical.md` | runtime placement, composition root, technical capability modules |
| `orchestration-data-transactions.md` | workflows, events, data ownership, transactions, cycles |
| `enforcement.md` | ArchUnit template, hard structural rules, tooling per stack |
| `review-checklist.md` | repeatable architecture review and report template |
| `language-mappings.md` | Java, C#, NestJS, Go |
| `architectural-intent.md` | full favors/avoids statement |

### `zed-project`

Set up a project for the [Zed editor](https://zed.dev) — auto-detects Java, .NET/C#, PHP, C++, or PlatformIO/Arduino and creates the right LSP and formatter config files.

## Install

Claude Code discovers personal skills at `~/.claude/skills/<skill-name>/SKILL.md`.

Clone the repository **outside** that directory and symlink each skill, so that `git pull` updates the installed skills:

```bash
git clone https://github.com/cintix/cintix-skills.git ~/Projects/cintix-skills
mkdir -p ~/.claude/skills

ln -s ~/Projects/cintix-skills/zed-project ~/.claude/skills/zed-project
ln -s ~/Projects/cintix-skills/modular-hybrid-architecture ~/.claude/skills/modular-hybrid-architecture
```

If a skill already exists at the destination, remove or move it first — a copy will not receive updates.

If your setup does not follow directory symlinks, copy the two skill folders into `~/.claude/skills/` instead, and re-copy them after pulling changes.

Restart Claude Code or start a new session. The skills are then available as `/zed-project` and `/modular-hybrid-architecture`.

## Update

```bash
cd ~/Projects/cintix-skills && git pull
```

Because the installed paths are symlinks, the new content is used the next time Claude Code loads the skills.

## Validate

```bash
./scripts/validate-skills.sh
```

Checks that every `*/SKILL.md` has valid frontmatter, that `name` matches its directory, that `description` is present and within limits, and that every `references/...` path resolves.

## Layout

```text
zed-project/
  SKILL.md

modular-hybrid-architecture/
  SKILL.md            # concise entry point
  references/         # detailed rules, loaded on demand

scripts/
  validate-skills.sh
```
