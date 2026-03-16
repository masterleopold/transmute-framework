# Transmute Framework

> **v2.2.0** — Template sync: TODO source annotations, verification grep commands, retention defaults, UTC timestamps, timeout guidance, role model detail, deployment recovery, per-feature escalation tracking

A Claude Code plugin that transforms business plans into production-ready products through **Plan Casting** — a 25-stage automated pipeline where AI agent teams read your business plan, generate specifications, scaffold a project, implement every feature, audit and harden the codebase, deploy it, and produce documentation.

You write the plan. Transmute casts it into reality.

## What is Plan Casting?

Plan Casting is the philosophy behind Transmute: **build everything in the business plan**. No MVP, no phased delivery, no feature cutting. Features are implemented in priority order (P0 → P3), but all are built. AI agent teams work autonomously through 25 stages — from tech stack selection to production deployment and user documentation.

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

→ Live Verification → Remediation → Visual Polish or Redesign → Deploy
        [6V]              [6R]              [6P / 6P-R]          [7]

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
| **6P-R** | Frontend Design Elevation | Interactive full design overhaul (alternative to 6P)                       |
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
| `/redesign`          | 6P-R  | Frontend design elevation        |
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
5. **Stages 6A–6P/6P-R audit and harden** — security, accessibility, performance, refactoring, resilience, documentation, visual verification
6. **Stage 7 is manual deployment** — you deploy, then the plugin runs smoke tests
7. **Stages 8–9 are ongoing** — process user feedback and maintain dependencies

The pipeline is **gate-enforced** — you cannot skip stages. Prerequisites are checked before each stage runs. If a stage fails, fix the issue and run `/transmute:cast resume`.

### Gate Logic (v2.0.0)

- **5B**: FAIL triggers RETRY (re-run Stage 5 for affected features) or ESCALATE (4+ Category C issues)
- **6V**: Dual gate system — PASS skips 6R, CONDITIONAL PASS routes to 6R, FAIL stops pipeline. Supports three scope modes: `full`, `critical`, `diff`
- **6R**: Max 3 internal fix-verify cycles per run before escalation
- **7V**: Binary gate — PASS proceeds to 7D, FAIL requires hotfix + re-deploy or rollback
- **6P**: Issues categorized as Omission (O), Execution (E), or Design (D)
- **6P-R**: Severity levels — Critical, Major, Minor
- **6A/B/C**: Run as parallel agents for safe concurrent execution
- **8 + 9**: NEVER run concurrently — feedback loop and dependency maintenance are mutually exclusive

### Credential Tier System

Four credential tiers gate pipeline progression:

| Tier | Gate | Credentials |
|------|------|-------------|
| :red_circle: Placeholder | Before Stage 3 | No `YOUR_*_HERE`, `TODO_*`, `CHANGE_ME`, `PLACEHOLDER` patterns in `.env.local` |
| :yellow_circle: Service | Before Stage 5 | Product service credentials must be real |
| :orange_circle: Deploy | Before Stage 7 | Deployment credentials configured |
| :large_blue_circle: Production | Before Stage 7V | Live environment credentials verified |

### Progress Tracking (v2.0.0)

Pipeline status now includes a **Blocked** state (`⏸ Blocked`) alongside existing statuses (`✅ Done`, `🔧 In Progress`, `⬜ Not Started`, `🔄 Needs Re-implementation`), enabling clear state transition tracking across all 25 stages.

## Agent Teams

Several stages use Claude Code Agent Teams to parallelize work:

- **Stage 1** (BRD): 5 writer agents + 3 review agents
- **Stage 2** (PRD): Multiple writer agents producing 18 document sections
- **Stage 5** (Implementation): Per-feature teams with backend, frontend, test, and reviewer agents
- **Stage 6A–6C**: Three audit stages run as parallel safety agents (concurrent execution safe by design)
- **Stage 6V/7V**: Scenario generation via `feature_scenario_generation.md` template for systematic test coverage

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
├── skills/                      # 23 stage skills
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
    ├── progress.md              # Progress tracking template
    ├── execution-guide.md       # Pipeline execution reference
    ├── feature_scenario_generation.md  # 6V/7V scenario generation
    └── rules-templates/         # 6 path-scoped rules templates
        ├── _api-contracts-template.md
        ├── _auth-template.md
        ├── _backend-template.md
        ├── _data-model-template.md
        ├── _frontend-template.md
        └── _testing-template.md
```

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated
- Node.js v18+ (v20.17.0+ for Stage 7D)
- A business plan (markdown or PDF files)

## Changelog

### v2.1.0

### v2.2.0

**Comprehensive Template Sync (2-Pass Deep Audit)**

**Rules Templates** (all 6 templates updated)
- Added `Source:` and `Confidence:` metadata to all `<!-- TODO -->` HTML comments for traceability
- Added post-render verification grep command to all template headers: `grep -n '\[.*\]' .claude/rules/<name>.md`
- Backend: Expanded validation phrasing ("in the same file as the function, not inline within the function body")
- Data Model: Added default 90-day retention with GDPR rationale; added "ALL timestamps are UTC" rule
- Auth: Added glob note for frontmatter clarity; added `[RBAC / ABAC / Custom]` permission model type; added per-tenant role scoping
- Testing: Added exponential backoff timeout guidance (`intervals: [100, 200, 500]`); expanded axe-core framework-specific integration patterns; explicit five-state enumeration
- Frontend: Design tokens note clarified (Stage 3 creates based on tech-stack.md design direction)
- API Contracts: Added source annotations to all TODO comments

**New Template File**
- Added `_rules-candidates.md` — staging area template for rule candidates from Stages 5B and 6R

**CLAUDE.md Template Updates**
- Pre-6V Setup: Expanded to numbered 2-step checklist (file copy + port verification)
- Stage 0: Expanded outputs list and skip conditions with section enumeration
- Stage 3 prerequisite: Added credential validation details
- .env.local timing: Expanded with backend deployment timing and mid-pipeline credential guidance
- 6A/6G scope: Added account linking, signup, logout to 6A; file uploads to 6G; added decision rule with edge cases
- 6V modes: Clarified applies to 6V only, not 7V (7V always SMOKE scope)
- 2B gate: Added "none P0-blocking" detail and assumption review conditional
- 5B gate: Expanded with detailed thresholds (PASS/CONDITIONAL/FAIL-RETRY/FAIL-ESCALATE), per-feature escalation tracking
- 6V gate: Added category definitions, flaky scenario exclusion from percentage, expanded routing rules
- 6R: Expanded skip conditions and key rules
- 7D: Added WARN description (documentation quality issues that don't block launch)
- Stage 7 prerequisites: Reordered (6H READY first)
- Added stage skip conditions and tips/troubleshooting cross-references
- Added Test Count Preservation rule to Part 1
- CONDITIONAL PASS cascading: Expanded 6H evaluation guidance

**Execution Guide Updates**
- Stage 6G: "Error Resilience Hardening" → removed "Error" from sub-stage name
- Stage 6R: "Remediation loop" → "Remediation cycle" terminology alignment
- 6V/6R: All "Category A/B" → "6V-A/6V-B" in fixability context
- 5B: "5B-A/B/C" → "Category A/B/C (no prefix)" for size-based categories
- Pre-6V Setup: Reorganized with CRITICAL file existence check
- Added Deployment Failure Recovery section (§ 7.1.2)
- Per-feature escalation: Expanded "consecutive" definition (per-feature, not global)
- 6V flaky handling: Added exclusion from gate percentage
- 6P/6P-R switching: Safer `git revert` approach (creates reversible commit)
- Credential gates: Expanded timing details
- Stage 0 skip: Added Project Initialization field requirement

**Feature Scenario Generation Updates**
- WARNING section expanded to multi-line with bullet points
- Implicit dependency algorithm: Added keyword detection rules for inference
- Added cycle detection and transitive reduction sections
- Negative variant counting: Explicit counting rules for Step 9 trimming
- User impact scoring: Detailed 0-8 point algorithm replacing general description
- Flaky scenario: Clarified exclusion from 6V gate percentage
- Progress audit checklist: Expanded with explicit status emoji enumeration

**Skill & Agent Updates**
- remediate/SKILL.md: Full "Category A/B/C" → "6V-A/6V-B/6V-C" migration; "loop" → "cycle"
- remediate/references: Same terminology migration across detailed guide
- verify/references: "Category A/B" → "6V-A/6V-B" in next steps
- transmute-pipeline agent: "Category A/B" → "6V-A/6V-B" in post-6V routing table

---

### v2.1.0

**6R Cycle Semantics**
- Clarified "Max 3 completed loops" → "Max 3 internal fix-verify cycles within a single 6R run" — cycles happen within one session, not across separate runs
- Added explicit FAIL recovery: "do NOT re-run 6R — manually fix 6V-C issues first, re-run 6V, then 6R if needed"

**6V Routing**
- Added explicit routing rules: PASS → skip 6R, CONDITIONAL PASS with 6V-A/B → run 6R, CONDITIONAL PASS with only 6V-C → skip 6R

**`6V-` Prefix Consistency**
- All fixability-based A/B/C categories now consistently use `6V-` prefix across all skills, agents, and templates to distinguish from Stage 5B's size-based categories

**Assumption Review Timing**
- New operator checkpoint between Stages 1 and 2B: review `_review-log.md` when BRD assumption volume ≥30%

**Stage Skill Updates**
- 5B (audit-completeness): Enhanced known failure patterns, multi-file classification, session recovery restructuring
- 6P (polish): Dark mode escalation to 6P-R, expanded prerequisites, 22 critical rules
- 6P-R (redesign): `6V-` prefix consistency
- 6R (remediate): Cycle terminology, FAIL recovery guidance

**Template Updates**
- CLAUDE.md: `.env.local` timing, Pre-Stage 3 setup, CONDITIONAL PASS cascading, enhanced gate criteria
- execution-guide.md: 6R gate table updated
- API contracts template: Bullet consolidation

### v2.0.0

**Gate Logic Overhaul**
- 5B: FAIL now triggers RETRY (re-run Stage 5 for affected features) or ESCALATE (4+ Category C issues)
- 6V: Dual gate system — PASS/CONDITIONAL PASS/FAIL routing with scenario-driven verification
- 6R: Max 3 internal fix-verify cycles per run before mandatory escalation
- 7V: Binary gate — PASS or FAIL (hotfix + re-deploy / rollback)
- 8 + 9: NEVER concurrent rule enforced

**Credential Tier System**
- Four tiers (:red_circle: Placeholder, :yellow_circle: Service, :orange_circle: Deploy, :large_blue_circle: Production) with specific credential names gating pipeline progression at Stages 3, 5, 7, and 7V

**Scenario Generation**
- New `templates/feature_scenario_generation.md` for systematic 6V/7V test scenario creation from PRD features and user flows

**New Template Files**
- `templates/execution-guide.md` — pipeline execution reference
- `templates/feature_scenario_generation.md` — scenario generation for 6V/7V
- 6 rules-templates: `_api-contracts-template.md`, `_auth-template.md`, `_backend-template.md`, `_data-model-template.md`, `_frontend-template.md`, `_testing-template.md`

**Enhanced Progress Tracking**
- Added `⏸ Blocked` status to progress file alongside existing states
- State transition diagram for pipeline flow visualization

**Path-Scoped Rules Enhancements**
- Confidence hierarchy for rule prioritization
- Auto-promote threshold for validated rules
- Staleness review for outdated path-scoped rules

**6V Scope Modes**
- Three verification modes: `full` (all features), `critical` (P0/P1 only), `diff` (changed files only)

**6P / 6P-R Categorization**
- 6P: Issues categorized as Omission (O), Execution (E), or Design (D)
- 6P-R: Severity levels — Critical, Major, Minor

**Parallel Safety**
- 6A/B/C explicitly designed for safe concurrent execution as parallel agents

### v1.0.0

- Initial release: 25-stage pipeline from business plan to production deployment

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on adding stages, modifying skills, and reporting issues.

## License

[MIT](LICENSE)
