# Transmute Framework

A Claude Code plugin that transforms business plans into production-ready products through **Plan Casting** — a 24-stage automated pipeline where AI agent teams read your business plan, generate specifications, scaffold a project, implement every feature, audit and harden the codebase, deploy it, and produce documentation.

You write the plan. Transmute casts it into reality.

## What is Plan Casting?

Plan Casting is the philosophy behind Transmute: **build everything in the business plan**. No MVP, no phased delivery, no feature cutting. Features are implemented in priority order (P0 → P3), but all are built. AI agent teams work autonomously through 24 stages — from tech stack selection to production deployment and user documentation.

## Installation

```bash
git clone https://github.com/masterleopold/transmute-framework.git
claude --plugin-dir ./transmute-framework
```

Requires [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed and authenticated.

## Quick Start

1. **Prepare your business plan** — write markdown files describing your product idea, target users, features, and business model.

2. **Create a project directory** and place your plan inside `plancasting/businessplan/`:
```bash
mkdir -p ~/my-project/plancasting/businessplan
cp my-plan.md ~/my-project/plancasting/businessplan/
cd ~/my-project
```

3. **Launch Claude Code** with the Transmute plugin:
```bash
claude --plugin-dir /path/to/transmute-framework
```

4. **Run the pipeline**:
```
/transmute:cast
```

5. **Resume if interrupted**:
```
/transmute:cast resume
```

## Pipeline

```
Business Plan → Tech Stack → BRD → PRD → Spec Validation → Scaffold
   [Input]        [0]       [1]   [2]      [2B]           [3+4]

→ Implementation → Completeness Audit → QA & Hardening → Pre-Launch
       [5]                [5B]              [6A-6G]         [6H]

→ Live Verification → Remediation → Visual Polish → Deploy
        [6V]              [6R]          [6P]          [7]

→ Production Smoke → User Guide → Feedback / Maintenance
        [7V]            [7D]         [8] / [9]
```

| Stage  | Name                        | What Happens                                                                |
| ------ | --------------------------- | --------------------------------------------------------------------------- |
| **0**  | Tech Stack Discovery        | Interactive — choose framework, database, hosting. Outputs `plancasting/tech-stack.md` |
| **1**  | BRD Generation              | 5 AI writer agents + 3 reviewers generate Business Requirements            |
| **2**  | PRD Generation              | Multiple agents produce 18-section Product Requirements                    |
| **2B** | Spec Validation             | Cross-validates BRD against PRD for consistency                            |
| **3**  | Scaffold Generation         | Creates full project skeleton from PRD                                     |
| **4**  | CLAUDE.md Verification      | *Manual* — verify Part 2 has project specifics                             |
| **5**  | Feature Implementation      | Agent teams implement every feature in priority order (P0→P3)              |
| **5B** | Implementation Audit        | Verifies all PRD features are actually implemented                         |
| **6A** | Security Audit              | OWASP vulnerabilities, auth issues, injection risks                        |
| **6B** | Accessibility Audit         | ARIA, keyboard nav, color contrast, screen reader support                  |
| **6C** | Performance Optimization    | Bottlenecks, bundle size, slow queries                                     |
| **6E** | Code Refactoring            | Cleans up issues found in 6A–6C                                            |
| **6F** | Seed Data Generation        | Realistic test/demo data                                                   |
| **6G** | Error Resilience            | Error handling, fallbacks, recovery                                        |
| **6D** | Documentation               | Developer docs, API references                                             |
| **6H** | Pre-Launch Verification     | Final readiness check                                                      |
| **6V** | Visual & Functional Verify  | UI matches specs, interactions work correctly                              |
| **6R** | Runtime Remediation         | Fixes 6V failures (skipped if 6V passes clean)                             |
| **6P** | Visual Polish               | Final UI refinements                                                       |
| **7**  | Deployment                  | *Manual* — deploy backend first, then frontend                             |
| **7V** | Production Smoke Tests      | End-to-end live deployment verification                                    |
| **7D** | User Guide Generation       | End-user documentation                                                     |
| **8**  | Feedback Loop               | User feedback → spec updates → code changes                               |
| **9**  | Dependency Maintenance      | Keep dependencies current (monthly/quarterly)                              |

## Commands

### Pipeline Controller

| Command                     | Description                        |
| --------------------------- | ---------------------------------- |
| `/transmute:cast`           | Run the full pipeline (Stages 0–9) |
| `/transmute:cast full`      | Same as above                      |
| `/transmute:cast resume`    | Resume from last completed stage   |
| `/transmute:cast <stage>`   | Run a specific stage               |
| `/transmute:cast help`      | Show all stage names               |

### Individual Stages

Each stage is also a standalone skill. Claude Code autocomplete shows them as short names with a `(transmute)` label:

| Command              | Stage | Description                      |
| -------------------- | ----- | -------------------------------- |
| `/tech-stack`        | 0     | Interactive tech stack discovery |
| `/brd`               | 1     | Business Requirements            |
| `/prd`               | 2     | Product Requirements             |
| `/validate-specs`    | 2B    | Spec validation                  |
| `/scaffold`          | 3     | Project scaffolding              |
| `/implement`         | 5     | Feature implementation           |
| `/audit-completeness`| 5B    | Implementation audit             |
| `/audit-security`    | 6A    | Security audit                   |
| `/audit-a11y`        | 6B    | Accessibility audit              |
| `/optimize`          | 6C    | Performance optimization         |
| `/docs`              | 6D    | Documentation                    |
| `/refactor`          | 6E    | Code refactoring                 |
| `/seed-data`         | 6F    | Seed data generation             |
| `/harden`            | 6G    | Error resilience                 |
| `/prelaunch`         | 6H    | Pre-launch verification          |
| `/verify`            | 6V    | Visual & functional verification |
| `/remediate`         | 6R    | Runtime remediation              |
| `/polish`            | 6P    | Visual polish                    |
| `/smoke`             | 7V    | Production smoke tests           |
| `/user-guide`        | 7D    | User guide generation            |
| `/feedback`          | 8     | Feedback loop                    |
| `/maintain`          | 9     | Dependency maintenance           |

Stages **4** and **7** are manual and cannot be invoked via commands.

## How It Works

1. **You provide a business plan** — markdown or PDF files describing your product
2. **Stage 0 is interactive** — you choose your tech stack (framework, database, auth, hosting, etc.)
3. **Stages 1–3 generate specs** — BRD, PRD (18 sections), and project scaffold
4. **Stage 5 builds the product** — per-feature agent teams (backend, frontend, test, reviewer) implement everything
5. **Stages 6A–6P audit and harden** — security, accessibility, performance, refactoring, resilience, documentation, visual verification
6. **Stage 7 is manual deployment** — you deploy, then the plugin runs smoke tests
7. **Stages 8–9 are ongoing** — process user feedback and maintain dependencies

The pipeline is **gate-enforced** — you cannot skip stages. Prerequisites are checked before each stage runs. If a stage fails, fix the issue and run `/transmute:cast resume`.

## Agent Teams

Several stages use Claude Code Agent Teams to parallelize work:

- **Stage 1** (BRD): 5 writer agents + 3 review agents
- **Stage 2** (PRD): Multiple writer agents producing 18 document sections
- **Stage 5** (Implementation): Per-feature teams with backend, frontend, test, and reviewer agents
- **Stage 6A–6C**: Three audit stages run as parallel agents

## Project Output

After running the pipeline, your project will contain:

```
your-project/
├── plancasting/                 # All pipeline artifacts
│   ├── businessplan/            # Your input (read-only)
│   ├── tech-stack.md            # Stage 0
│   ├── brd/                     # Stage 1
│   ├── prd/                     # Stage 2 (18 sections)
│   ├── _progress.md             # Pipeline tracking
│   ├── _scaffold-manifest.md    # Stage 3
│   ├── _audits/                 # All audit reports
│   ├── _launch/                 # Pre-launch reports
│   └── _maintenance/            # Stage 9 reports
├── CLAUDE.md                    # Project conventions
├── .env.local                   # Credentials
├── src/                         # Product code
├── docs/                        # Developer documentation
├── seed/                        # Seed data
└── user-guide/                  # End-user guide
```

## Plugin Architecture

```
transmute-framework/
├── .claude-plugin/plugin.json   # Plugin manifest
├── commands/cast.md             # /transmute:cast entry point
├── agents/
│   ├── transmute-pipeline.md    # Full pipeline orchestrator
│   ├── brd-writer.md            # BRD section writer
│   ├── prd-writer.md            # PRD section writer
│   ├── feature-backend.md       # Backend implementation
│   ├── feature-frontend.md      # Frontend implementation
│   ├── feature-tests.md         # Test writing
│   └── feature-reviewer.md      # Code review gate
├── skills/                      # 22 stage skills
│   ├── tech-stack/              # Stage 0
│   ├── brd/                     # Stage 1
│   ├── prd/                     # Stage 2
│   └── ...                      # One directory per stage
├── hooks/
│   ├── hooks.json               # Gate enforcement registration
│   └── scripts/
│       └── check-prerequisites.sh
└── templates/
    ├── CLAUDE.md                # Project CLAUDE.md template
    └── progress.md              # Progress tracking template
```

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated
- Node.js v18+ (v20.17.0+ for Stage 7D)
- A business plan (markdown or PDF files)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on adding stages, modifying skills, and reporting issues.

## License

[MIT](LICENSE)
