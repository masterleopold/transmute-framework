# Rules Candidates

> **Auto-generated staging area for rule candidates.** Do not edit the format section below.

## Purpose

During pipeline execution, Stages 5B (Completeness Audit) and 6R (Remediation) discover recurring implementation patterns and anti-patterns. Instead of immediately adding them to `.claude/rules/`, they are staged here as candidates for human review.

## Review Workflow

1. **Stages 5B and 6R** append candidates to this file when they identify a repeatable pattern. (Stage 3 generates starter rules directly to `.claude/rules/` at HIGH confidence — it does not use this candidates file.)
2. **Operator reviews** candidates after each stage completes.
3. **Promote, edit, or discard** based on confidence level:
   - **HIGH** — Promote directly to the target `.claude/rules/` file. Copy the Rule Text verbatim.
   - **MEDIUM** — Edit the Rule Text to generalize, then promote to `.claude/rules/`.
   - **LOW** — Keep for observation. Promote if the pattern recurs in a later stage. Discard if it does not recur after two more stages.

## Confidence Criteria

- **HIGH**: 2+ distinct features (separate FEAT-IDs) affected with a clear, repeatable pattern. Two occurrences within the same feature count as 1 feature.
- **MEDIUM**: Single feature affected, but the pattern is generalizable to other features. The rule would likely prevent similar issues.
- **LOW**: Edge case, uncertain whether the pattern will recur, or the fix is context-dependent. Discard if the pattern does not recur in the next two rounds of Stage 5B or 6R execution.

## Candidate Format

Each candidate follows this structure:

```markdown
### [Descriptive Title]
- **Source Stage**: 5B / 6R
- **Evidence**: [issue ID, commit hash, or PRD ref]
- **Trigger**: [what situation triggers this rule]
- **Rule Text**: [the actual rule to add to .claude/rules/]
- **Target File**: `.claude/rules/[filename].md` (include full path)
- **Confidence**: HIGH / MEDIUM / LOW
- **Affected Features**: [list of FEAT-IDs]
```

---

## Staleness Policy

Maximum 30 candidates at any time. If exceeded, discard the oldest LOW-confidence candidates first. **Staleness timeline**: A candidate is "stale" if it was created >60 calendar days ago AND has not been promoted, edited, or re-triggered by a new Stage 5B/6R finding. During each Stage 9 run, the operator reviews stale candidates and either promotes (if still valid) or removes them. Candidates pending for 2+ Stage 9 maintenance cycles without promotion are automatically removed. This prevents stale candidates from accumulating indefinitely. See `plancasting/transmute-framework/prompt_maintain_dependencies.md` § "Path-Scoped Rules Staleness Review" for the review procedure.
See also CLAUDE.md Part 1 § 'Path-Scoped Rules (`.claude/rules/`)' for the full rules specification.

---

## Candidates

<!-- Stages 5B and 6R append candidates below this line. -->

> **Example entry** (for reference only — delete this block when the first real candidate is added):
>
> ### Convex Query Requires Index for Pagination
> - **Source Stage**: 5B
> - **Evidence**: FEAT-002 (task list), FEAT-005 (activity feed)
> - **Trigger**: Any paginated query using `.paginate()` on a Convex table
> - **Rule Text**: Every `.paginate()` call must use an indexed query — unindexed pagination silently falls back to full table scan, causing timeouts on tables with 1000+ rows.
> - **Target File**: `.claude/rules/backend.md`
> - **Confidence**: HIGH
> - **Affected Features**: FEAT-002, FEAT-005
