# Contributing to Transmute Framework

Thank you for your interest in contributing to Transmute. This guide covers how the plugin is structured and how to make changes.

## Plugin Architecture

```
transmute-framework/
├── .claude-plugin/plugin.json   # Plugin manifest
├── commands/cast.md             # Pipeline controller (/transmute:cast)
├── agents/                      # 7 agent definitions (pipeline orchestrator + feature teams)
├── skills/                      # 22 stage skills (one per pipeline stage)
│   └── <stage-name>/
│       ├── SKILL.md             # Skill definition with frontmatter + instructions
│       └── references/          # Optional detailed guides loaded via ${CLAUDE_SKILL_ROOT}
├── hooks/
│   ├── hooks.json               # Hook registration (PreToolUse gate enforcement)
│   └── scripts/
│       └── check-prerequisites.sh   # Gate enforcement script
└── templates/
    ├── CLAUDE.md                # Generated project CLAUDE.md template
    └── progress.md              # Progress tracking template
```

## How to Add a New Stage

1. Create a skill directory: `skills/<stage-name>/SKILL.md`
2. Add frontmatter with `name`, `description`, and `version`
3. Add the stage to the mapping table in `commands/cast.md`
4. Add prerequisite checks in `hooks/scripts/check-prerequisites.sh`
5. Add the stage row to `agents/transmute-pipeline.md` Stage Skills Map
6. If the stage has complex instructions, add a `references/` subdirectory

## How to Modify an Existing Stage

1. Read the full SKILL.md — understand what it does
2. If the skill has a `references/` directory, read those too
3. Make your changes
4. Test by running the stage against a sample business plan

## File Conventions

- **Paths**: Project artifacts use `./plancasting/` prefix. Code output dirs (`src/`, `docs/`, `seed/`) stay at project root
- **Plugin variables**: Use `${CLAUDE_SKILL_ROOT}` for skill-internal paths, `${CLAUDE_PLUGIN_ROOT}` for plugin-root paths
- **Skill names**: Short names without prefix (e.g., `brd`, not `transmute-brd`)

## Testing

There is no automated test suite — the plugin is prompt engineering, not traditional code. To validate changes:

1. Create a test project with a simple business plan in `plancasting/businessplan/`
2. Run the modified stage: `/transmute:cast <stage-name>`
3. Verify the output matches expectations

## Reporting Issues

When filing a bug report, include:
- Stage number and name
- Business plan type (what kind of product)
- The error or unexpected output
- Claude Code version (`claude --version`)

## Code Style

- Markdown files use `---` frontmatter delimiters
- YAML values with colons must be quoted
- Prefer explicit instructions over implicit assumptions in skill prompts
