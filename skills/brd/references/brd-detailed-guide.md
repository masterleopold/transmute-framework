# BRD Generation — Detailed Guide

## Role

You are a senior business analyst and solution architect acting as the TEAM LEAD for a multi-agent BRD generation project. Generate a comprehensive, enterprise-grade Business Requirement Document (BRD) from the provided Business Plan using Claude Code Agent Teams.

**Stage Sequence**: Business Plan → 0 (Tech Stack) → **1 (this stage)** → 2 (PRD) → 2B (Spec Validation) → 3+4 (Scaffold + CLAUDE.md) → 5 (Implementation) → 5B (Audit) → 6A/6B/6C (parallel) → 6E → 6F → 6G → 6D → 6H → 6V → 6R → 6P/6P-R → 7 (Deploy) → 7V → 7D → 8 (Feedback) / 9 (Maintenance)

## Critical Framing: Full-Build Approach

This BRD assumes ALL features and capabilities described in the Business Plan will be built and delivered as a single, complete product. There is no MVP, no phased rollout, and no feature deferral. Every capability mentioned — regardless of how it was originally sequenced — must be captured as a requirement with the same level of detail and urgency. If the Business Plan describes "Phase 1, Phase 2, Phase 3" or similar staging, IGNORE the phasing and treat all described functionality as part of a single unified scope. Features labeled "future", "planned", "roadmap", or "long-term" are INCLUDED. Only features explicitly marked "out-of-scope" or "explicitly not planned" are excluded.

## Known Failure Patterns

1. **Vague acceptance criteria**: Using unmeasurable adjectives ("fast response time", "intuitive interface", "scalable architecture"). ALWAYS include specific metrics (e.g., "response time < 200ms", "task completion in < 3 clicks").
2. **Copy-pasting business plan text**: Agent copies business plan sentences verbatim as requirements instead of translating into structured requirement format with IDs, priority, and traceability.
3. **MoSCoW inflation**: All requirements marked "Must Have" because the full-build approach is misinterpreted as "everything is critical." Maintain proper priority distribution — Must/Should/Could/Won't should reflect both criticality and implementation dependency order. A healthy distribution: Must 50–65%, Should 20–30%, Could 10–15%, Won't 0–5% (reserved for features explicitly considered and rejected — features NOT described in the Business Plan at all). Never use Won't Have for Business Plan features marked as 'future' or 'phase 2' — in the full-build approach, those are still in-scope.
4. **Missing negative requirements**: Only specifying what the system MUST do, never what it MUST NOT do (e.g., "the system must NOT allow users to access other organizations' data").
5. **Circular traceability**: FR traces to BR, but BR just restates the FR in different words. Each requirement level must add specificity.
6. **NFRs without measurement methods**: Specifying "99.9% uptime" without defining how uptime is measured, what counts as downtime, or how it is monitored.
7. **Mermaid syntax errors**: Diagrams with invalid syntax that silently fail to render. ALWAYS validate mermaid syntax before including. Common errors: (a) missing quotes around node labels containing special characters, (b) incorrect arrow syntax (`A --> B` not `A -> B` for flowcharts), (c) unclosed subgraph blocks, (d) using Unicode arrows instead of ASCII arrows.
8. **Thin business plan extrapolation**: When the business plan is sparse, agent generates assumptions that contradict the business plan's implied intent. If more than 30% of total requirements across all categories must be assumed (not derived from the Business Plan), flag this as CRITICAL in the final summary and recommend the user review assumptions before proceeding to Stage 2.

## Input

Read all files in `./plancasting/businessplan/` directory. Supported formats: `.md` (markdown) and `.pdf` (read using the PDF reading tool). These files constitute the complete Business Plan. Thoroughly analyze every section — including but not limited to: executive summary, market analysis, competitive landscape, product/service description, revenue model, go-to-market strategy, operational plan, financial projections, risk assessment, and organizational structure. Pay special attention to any features, capabilities, or functionality described across ALL phases, tiers, or future roadmap items — these must ALL be included as current-scope requirements.

## Stack Adaptation

Adapt based on product type in `plancasting/tech-stack.md`:
- **Web applications**: Standard structure
- **Mobile applications**: Add platform-specific requirement categories
- **IoT / Embedded**: Add hardware requirement categories
- **Desktop applications**: Add platform-specific requirements
- **AI/ML products**: Add model requirement categories

**Language**: Check `Session Language` in `./plancasting/tech-stack.md`. Generate ALL BRD documents in specified language. Technical identifiers remain in English.

**Language Inheritance**: Subsequent stages (PRD, audits, reports) will read the `Session Language` section from `plancasting/tech-stack.md` — NOT from BRD documents.

## Output

Generate the BRD as markdown files under `./plancasting/brd/` directory. Each file self-contained yet cross-referenced. Generate `README.md` as navigation hub.

## Expected Output Files

- `00-cover-and-metadata.md` — Document metadata, version, revision history, approval table, TOC
- `01-executive-summary.md` — Problem statement, proposed solution, KPIs, critical success factors
- `02-project-background-and-objectives.md` — Business context, SMART objectives, strategic alignment, ROI
- `03-current-state-analysis.md` — As-is processes, gap analysis, pain points, process flows
- `04-stakeholder-analysis.md` — Stakeholder table, RACI matrix, communication plan, escalation paths
- `05-scope-definition.md` — In/out scope, change control
- `06-business-requirements.md` — Numbered BRs with rationale, priority (MoSCoW), acceptance criteria, traceability matrix
- `07-functional-requirements.md` — FRs in user story format, traced to BRs, organized by module
- `08-non-functional-requirements.md` — Performance, scalability, availability, accessibility, i18n, disaster recovery
- `09-data-requirements.md` — Data model, data flows, data quality, volume projections, retention, privacy classification
- `10-integration-requirements.md` — Systems list, integration patterns, API specs, third-party dependencies
- `11-user-experience-requirements.md` — Personas, user journeys, UI/UX principles, responsive design, brand adherence
- `12-regulatory-and-compliance-requirements.md` — Applicable laws/regulations, industry standards, audit trails, data residency
- `13-security-requirements.md` — AuthN/AuthZ, encryption, OWASP Top 10, monitoring, incident response
- `14-business-rules-and-logic.md` — Business rule catalog, decision tables, workflow state transitions
- `15-reporting-and-analytics-requirements.md` — Reports/dashboards list, KPI definitions, analytics capabilities
- `16-migration-and-transition-requirements.md` — Migration strategy, data mapping, rollback, training, go-live checklist
- `17-acceptance-criteria.md` — UAT approach, test scenarios, entry/exit criteria, defect classification, sign-off process
- `18-assumptions-constraints-dependencies.md` — Assumptions/constraints/dependencies tables with impact analysis
- `19-risk-analysis-and-mitigation.md` — Risk register, risk heat map, top 10 risks with mitigation, monitoring cadence
- `20-cost-benefit-analysis.md` — Cost breakdown, benefits quantification, NPV, payback period, sensitivity analysis, TCO
- `21-timeline-and-milestones.md` — Milestone table, Gantt chart, critical path, decision gates
- `22-glossary-and-appendices.md` — Consolidated glossary, cross-reference matrix
- `_context.md` — Shared context (Business Plan summary, feature inventory, ID registry, glossary)
- `_review-log.md` — Review date, issues found/resolved by severity, remaining issues
- `README.md` — BRD overview, navigation guide, file descriptions, reading order, conventions

Expected total: 26 files (23 numbered specification files + 3 supporting files)

## Agent Team Architecture

### Phase 1: Lead Analysis & Planning

**Prerequisite Verification**:
- Verify `./plancasting/businessplan/` exists with `.md` or `.pdf` files. If missing: STOP.
- Verify `./plancasting/tech-stack.md` exists. If missing: STOP.

Steps:
1. Read and internalize all files in `./plancasting/businessplan/` and `./plancasting/tech-stack.md`.
2. **Feature Extraction Sweep**: Identify EVERY feature across ALL phases. Compile master feature inventory. **Deduplication rule**: Merge variants of same capability; keep distinct features separate. **Variant test**: Two features are variants if they share the same user goal AND the same core data entity AND the same business logic. Different delivery channels for the same entity with the same trigger rules ARE variants — merge them. But if channels have divergent business logic, treat as separate. When in doubt, keep separate.
3. Create `./plancasting/brd/` directory.
4. Create `./plancasting/brd/_context.md` containing:
   - Business Plan summary
   - Technology stack summary
   - Master feature inventory as markdown table with columns: Feature ID (FEAT-001, etc.), Feature Name, Business Plan Section, FR ID(s), Coverage Status (Assigned to FR / Needs FR / Explicit Exclusion (rare))
   - Master requirement ID registry with reserved ranges:
     - BR-001–BR-099: Business Requirements
     - FR-001–FR-299: Functional Requirements (expanded)
     - NFR-001–NFR-099: Non-Functional Requirements
     - CR-001–CR-049: Compliance & Regulatory
     - SR-001–SR-049: Security Requirements
     - BRL-001–BRL-149: Business Rules & Logic (expanded)
     - DR-001–DR-049: Data Requirements
     - IR-001–IR-049: Integration Requirements
   - Glossary
   - Cross-reference conventions
   - Note: "This BRD covers the COMPLETE product scope."
5. Create task list with dependency tracking.

### Phase 2: Spawn Specialized Teammates

Spawn 5 teammates. **Known dependency**: Teammate 3 depends on Teammate 2 for security/compliance context. Either spawn Teammate 3 after Teammate 2, or include security context in Teammate 3's spawn prompt.

Each teammate's spawn prompt MUST include: CLAUDE.md instructions, full `_context.md`, file assignments and ID ranges, relevant Business Plan sections, full-scope instruction, writing guidelines.

#### Teammate 1: "business-core"
**Domain**: Business strategy and functional requirements
**Files**: `00-cover-and-metadata.md`, `01-executive-summary.md`, `02-project-background-and-objectives.md`, `03-current-state-analysis.md`, `06-business-requirements.md`, `07-functional-requirements.md`
**ID ranges**: BR-001–BR-099, FR-001–FR-299

**Spawn prompt must emphasize**: Every BR and FR must trace back to a specific Business Plan section. Use quantified acceptance criteria. Generate mermaid diagrams for all process flows. The functional requirements must cover ALL features from the master feature inventory — including those originally described as future phases. The FR range is expanded (FR-001–FR-299) to accommodate the full scope.

#### Teammate 2: "technical-infrastructure"
**Domain**: Non-functional, security, and compliance requirements
**Files**: `08-non-functional-requirements.md`, `12-regulatory-and-compliance-requirements.md`, `13-security-requirements.md`
**ID ranges**: NFR-001–NFR-099, CR-001–CR-049, SR-001–SR-049

**Spawn prompt must emphasize**: Non-functional requirements must be sized for the COMPLETE product (all features active simultaneously, full user base from day one). Do not size for an MVP subset. Scalability targets should reflect the Business Plan's full growth projections. If not explicitly stated, mark as assumptions.

#### Teammate 3: "data-and-integration"
**Domain**: Data architecture, integrations, and migration
**Files**: `09-data-requirements.md`, `10-integration-requirements.md`, `16-migration-and-transition-requirements.md`
**ID ranges**: DR-001–DR-049, IR-001–IR-049

**Spawn prompt must emphasize**: The data model must accommodate ALL entities across ALL features from day one. Do not design a minimal schema that would need expansion later. Integration requirements must cover ALL third-party systems mentioned anywhere in the Business Plan, including those described as future integrations.

#### Teammate 4: "user-experience-and-operations"
**Domain**: UX, business rules, reporting, and analytics
**Files**: `04-stakeholder-analysis.md`, `05-scope-definition.md`, `11-user-experience-requirements.md`, `14-business-rules-and-logic.md`, `15-reporting-and-analytics-requirements.md`
**ID ranges**: BRL-001–BRL-149

**Spawn prompt must emphasize**: Scope definition file (`05`) must explicitly state that ALL features from the Business Plan are in-scope. There is no MVP definition or phase breakdown. The in-scope list must be exhaustive. The out-of-scope section only contains items NOT mentioned in the Business Plan at all. Derive personas from ALL customer segments. Business rules must cover ALL feature interactions, including cross-feature rules that only emerge when everything is built together.

#### Teammate 5: "risk-and-planning"
**Domain**: Risk, cost-benefit, timeline, acceptance, and constraints
**Files**: `17-acceptance-criteria.md`, `18-assumptions-constraints-dependencies.md`, `19-risk-analysis-and-mitigation.md`, `20-cost-benefit-analysis.md`, `21-timeline-and-milestones.md`

**Spawn prompt must emphasize**: Risk analysis must include the additional risks specific to a full-build approach (complexity risk, integration risk from building all features simultaneously, testing scope risk). Cost-benefit analysis should reflect the complete build cost vs. the benefit of delivering all features at once (faster time-to-full-value, no re-architecture costs). Timeline must be structured around parallel workstreams, NOT sequential phases. Use a Gantt chart showing concurrent development. Milestones should mark completion of functional areas, not phase gates.

### Token Budget Management

Each spawned agent has an output token limit per response (see tech-stack.md § Model Specifications "Output token limit"). Safe output budget per agent: output token limit minus 7K headroom for formatting overhead, error recovery, and retry margin.

#### Estimation Heuristics
- Each FR with full detail: ~200-400 tokens
- Each BRL with decision table: ~150-300 tokens
- Each DR with schema detail: ~200-400 tokens
- Each NFR with quantified targets: ~150-250 tokens
- Tables, mermaid diagrams, cross-references: +30% overhead

#### Estimation Formula

```
Total ≈ (BRs × 150) + (FRs × 300) + (NFRs × 200) + (CRs × 100) + (SRs × 100) + (BRLs × 150) + (DRs × 200) + (IRs × 100) + (Diagrams × 300) + (Glossary terms × 50) + 2000 overhead
```

Diagram complexity varies: simple flow (~150 tokens), complex state machine (~500 tokens). Cross-reference overhead scales with feature count — add ~10% for projects with 100+ FRs.

#### Splitting Rules
1. Estimate output size for each file.
2. If single file exceeds safe output budget: split by feature group/module.
3. If teammate's combined files exceed safe budget: split into multiple agents.
4. Lightweight files can be grouped.

#### Split Spawn Protocol
When splitting a teammate:
- Each sub-agent gets the SAME context (`_context.md`, writing guidelines, full-scope instruction)
- Each sub-agent gets a UNIQUE ID range subset (e.g., sub-agent A gets FR-001–FR-099, sub-agent B gets FR-100–FR-199)
- Each sub-agent's spawn prompt specifies EXACTLY which features/modules it covers
- The lead tracks all sub-agents and merges their outputs in Phase 4

#### Known Heavy Files
- `07-functional-requirements.md` — almost certainly exceeds safe budget with 30+ features. Split by feature group.
- `14-business-rules-and-logic.md` — monitor and split if complex cross-feature rules.

#### Teammate Failure Recovery
1. Check which files were successfully written.
2. Re-spawn for missing files.
3. Re-spawn for truncated files, instructing completion from last complete section.
4. If re-spawned teammate's output is still truncated after reducing scope, split further. Do NOT retry the same scope more than once.
5. Do NOT proceed to Phase 4 until all assigned files are complete.

### Phase 3: Coordination During Execution

Monitor progress, front-load shared context in spawn prompts, resolve conflicts, ensure consistency for full-build interactions. Teammates communicate intermediate results to the lead via completion messages — teammates should NOT write directly to `_context.md` (the lead manages that file).

### Phase 4: Structural Integration

1. Collect all files into `./plancasting/brd/`.
2. Perform structural consistency checks:
   - Full-scope coverage audit (every feature → at least one FR)
   - ID uniqueness (no cross-teammate duplicates)
   - Cross-reference link validation
   - Terminology consistency with glossary
   - Assumption markers confirmed
   - Assumption volume check (>30% = CRITICAL). Calculation: count of `> ⚠️ ASSUMPTION:` blockquotes / count of unique requirement IDs × 100.
   - Mermaid syntax validation
   - BR → FR mapping check (every BR has at least one FR)
   - MoSCoW distribution check (Must Have >70% = flag). When deviation may be acceptable: enterprise/regulated products or products with many interdependent features. RED FLAG: if Business Plan describes 'MVP first, phases later' but all requirements are Must Have.
   - **Cross-feature interaction check**: Identify requirements that interact across originally-separate phases. Ensure documented.
3. Generate `22-glossary-and-appendices.md`
4. Generate `README.md` with prominent full-scope note
5. Fix structural inconsistencies

### Phase 5: Deep Quality Review

Spawn 3 review agents. Each reads ALL BRD files, `_context.md`, and the Business Plan. If combined BRD files exceed 60% of the model's context window (check tech-stack.md § Model Specifications), split review scope by domain.

#### Review Agent Spawn Protocol
Each review agent's spawn prompt MUST include:
- "Read CLAUDE.md Part 1 (immutable rules) if it exists. Follow its conventions."
- List of all generated BRD files to review
- Instructions to read every file in `./plancasting/brd/` and relevant businessplan files
- The issue report format
- Their specific review checklist

#### Issue Report Format

```markdown
## [AGENT-NAME] Review Report

### Issue [N]
- **Severity**: CRITICAL | HIGH | MEDIUM | LOW
- **File**: [filename]
- **Location**: [section/requirement ID]
- **Category**: [from agent's checklist]
- **Description**: [What is wrong]
- **Recommendation**: [How to fix it]
- **Affected Requirements**: [List of requirement IDs impacted]
```

Severity definitions:
- **CRITICAL**: Requirement is missing, contradictory, or would cause implementation failure. Blocks development.
- **HIGH**: Requirement is vague, incomplete, or technically infeasible. Would cause rework.
- **MEDIUM**: Quality issue that reduces clarity but doesn't block development. Inconsistency or missing detail.
- **LOW**: Polish issue — formatting, minor terminology drift, optimization suggestion.

#### Review Agent 1: "completeness-reviewer"
Focus: Coverage gaps, vagueness, traceability. Checklist: FR coverage for every feature, measurable acceptance criteria, all states documented, integration requirements complete, security requirements testable, compliance citations, quantified NFRs, reasonable assumptions, no placeholders, cross-feature interactions, no verbatim Business Plan copies.

#### Review Agent 2: "consistency-reviewer"
Focus: Contradictions, duplications, terminology. Checklist: No contradictions, no duplicate requirements, consistent terminology, consistent MoSCoW priorities, consistent numerical targets, consistent user roles, consistent data entities, no conflicting business rules, integration-stack alignment, timeline-scope alignment, cost-complexity alignment.

#### Review Agent 3: "technical-reviewer"
Focus: Technical feasibility, accuracy, completeness. Checklist: Tech stack feasibility, realistic NFRs, data model completeness, real APIs/services, current security practices, scalability-infrastructure alignment, valid mermaid diagrams, full-feature-set performance, realistic data volumes, achievable DR/backup, appropriate optimization strategies.

### Phase 6: Remediation

1. Consolidate review reports, remove duplicates (keep most detailed version). Count issues by severity.
2. Quality Gate: CRITICAL/HIGH = mandatory remediation. MEDIUM/LOW = fix efficiently or document.
3. Fix root causes, not symptoms. When fixing contradictions, consult the Business Plan. When adding missing requirements, follow existing ID conventions.
4. **Remediation Principles**: Rewrite vague acceptance criteria properly (not just adding one word of specificity). Update ALL files referencing the incorrect version. Adjust technically infeasible requirements while preserving business intent.
5. **Second pass** (conditional): If >15 CRITICAL+HIGH fixes, targeted re-review of ONLY modified files. Single re-review pass — if new CRITICAL issues found, document them rather than entering a recursive loop.
6. Create `./plancasting/brd/_review-log.md` containing:
   - Review date and agent versions
   - Total issues found by severity (original counts)
   - Issues resolved by severity
   - Remaining MEDIUM/LOW issues
   - Any unresolvable CRITICAL/HIGH issues with explanation
   - **Assumption Review Status** section (required if assumption volume ≥ 30%):
     ```markdown
     ## Assumption Review Status
     - **Assumption volume**: [N]% ([count] assumptions / [count] requirement IDs)
     - **Flagged as CRITICAL**: YES / NO
     - **Operator reviewed**: NO (operator must change to YES after reviewing assumptions before Stage 2)
     - **Date reviewed**: —
     - **Operator notes**: —
     ```
7. **Final Summary**: Output totals: requirement counts by category, feature inventory coverage, assumptions flagged, assumption volume percentage (if ≥ 30%, recommend Business Plan remediation), mermaid diagrams generated, cross-feature interactions identified, quality metrics (found/resolved/remaining by severity), quality score (% of CRITICAL+HIGH resolved, target: 100%).

### Phase 7: Shutdown

Verify all output files exist in `./plancasting/brd/`. Expected: 26 files.

## Writing Guidelines

1. **Full Scope**: Every feature in-scope. Ignore phasing.
2. **Traceability**: Every requirement traces to Business Plan section. Use explicit references (e.g., "Derived from Business Plan § Market Analysis").
3. **Measurability**: Measurable acceptance criteria. No vague terms without quantification.
4. **Completeness**: Generate assumptions marked with `> ⚠️ ASSUMPTION: [text explaining reasoning and impact]` for gaps. Never leave sections empty.
5. **Consistency**: Use `_context.md` terminology. Define new terms and notify lead for glossary inclusion.
6. **Mermaid Diagrams**: For all diagrams. Wrap in mermaid-tagged code blocks.
7. **Cross-references**: Relative markdown links (e.g., `[See FR-003](./07-functional-requirements.md#fr-003)`).
8. **Professional Tone**: Clear, precise, active voice, session language.
9. **Structured Tables**: For all structured data.
10. **Depth**: Enterprise-grade, exhaustive. Each file a standalone reference for its domain.
11. **Requirement IDs**: Follow `_context.md` format and ranges. Ensure uniqueness within assigned range.
12. **Cross-Feature Interactions**: Consider interactions across all features. Document explicitly.
13. **Lowercase Anchors**: Use lowercase in heading IDs and cross-reference links (`#br-001` not `#BR-001`).
