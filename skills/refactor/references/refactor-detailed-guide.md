# Refactoring Detailed Guide — Teammate Prompts and Protocols

This file contains the full teammate spawn prompts, analysis criteria, and coordination protocols for Stage 6E Code Refactoring.

## Known Failure Patterns

Be aware of these observed refactoring failures:

1. **Behavioral changes disguised as refactoring**: Renaming a function AND changing its default behavior in the same commit. Every refactoring must preserve behavior.
2. **Dead code that is not dead**: Code that appears unused but is dynamically imported (`require()`, route-based code splitting, or referenced in configuration files). ALWAYS search for string-based references before deleting.
3. **Parallel teammate file conflicts**: Two teammates modify the same file. One teammate's import reorganization breaks another's extracted function. Coordinate shared file modifications.
4. **Schema index removal**: Index appears unused in code but is relied on by a production query pattern not covered by tests. NEVER remove indexes without verifying all query patterns.
5. **Extract-and-replace subtle changes**: Extracting code into a new function introduces slightly different default parameter handling. ALWAYS verify exact behavioral equivalence. After extracting shared logic into a helper, add a verification test confirming both original call sites produce identical results with the shared function.
6. **Missing test coverage for refactored code**: Refactoring code that has no tests means regressions cannot be detected. Add tests BEFORE refactoring, not after.

## Refactoring Opportunity Analysis Criteria

| Category | What to look for |
|---|---|
| Duplication | Similar functions, components, or patterns across feature domains. Extract if: function appears 2+ times with >90% code similarity, or extracting reduces total lines by >15%, OR function appears 3+ times regardless of similarity. |
| Abstraction | Repeated logic that should be extracted into shared modules |
| Consistency | Naming, patterns, or conventions that vary across features |
| Schema | Redundant indexes, tables that could be merged, unused fields |
| Coupling | Feature code that directly imports from another feature's internals |
| Dead code | Unused exports, unreachable branches, commented-out code |
| File structure | Files exceeding 300 lines, unclear module boundaries |

## Teammate 1: backend-refactorer

Scope: Backend functions, schema, and server-side code.

Spawn prompt:

```
You are refactoring the backend codebase for improved quality and maintainability.

CARDINAL RULE: No behavioral changes. Every existing test must still pass after your changes.

Read CLAUDE.md first. Check ./plancasting/tech-stack.md for the Session Language setting. Write all findings in that language. Then read ./plancasting/_audits/refactoring/plan.md for your assigned refactoring tasks.

Your tasks:

1. FUNCTION DEDUPLICATION: Scan all backend files.
   - Identify functions across different domain files that perform similar logic (e.g., two different "getByUserId" patterns, similar validation helpers, duplicated permission checks).
   - Extract shared logic into a shared helpers module.
   - Update all call sites to use the shared function.
   - Maintain JSDoc traceability on shared functions.

2. SCHEMA OPTIMIZATION: Review the schema file.
   - Identify redundant indexes (fields that are a prefix of another index).
   - Identify unused indexes (not referenced by any index call).
   - BEFORE REMOVING ANY INDEX: (1) search all backend files for index references, (2) check schema comments for documented usage rationale, (3) if production query logs are accessible, verify truly unused. If zero references AND no rationale AND no production usage: safe to remove. Otherwise keep and document.
   - DO NOT remove tables or rename fields — only remove provably unused indexes and fields.

3. CONSISTENCY ENFORCEMENT: Scan all backend functions.
   - Unify error handling patterns (consistent error type usage).
   - Unify authentication check patterns (shared auth helper).
   - Unify argument validation patterns.
   - Ensure all functions follow: args -> auth -> validate -> logic -> return.

4. DEAD CODE REMOVAL: Scan all backend files.
   - Remove unused exports (never imported anywhere).
   - Remove commented-out code blocks.
   - Remove unreachable code paths.
   - Before deleting any export: search for string-based references (excluding node_modules, .next, dist), search config files, search route-based code splitting patterns. Also search for dynamic imports and bracket notation access patterns.
   - If any doubt remains, mark as candidate for manual review rather than deleting.

5. FILE ORGANIZATION: Split any backend file exceeding 300 lines into logically coherent smaller files. Re-export from the original file for backwards compatibility.

6. VERIFICATION: After ALL changes, run backend tests. If ANY test fails, revert the causing change and find an alternative approach.

Report: files modified, functions extracted/shared, indexes removed, dead code removed, test results (must be 100% pass).
```

## Teammate 2: frontend-component-refactorer

Scope: React components and page structure.

Spawn prompt:

```
You are refactoring frontend components for improved quality and maintainability.

CARDINAL RULE: No behavioral changes. Every existing test must still pass after your changes.

Read CLAUDE.md first. Check ./plancasting/tech-stack.md for the Session Language setting. Write all findings in that language. Then read ./plancasting/_audits/refactoring/plan.md for your assigned refactoring tasks.

Your tasks:

1. COMPONENT DEDUPLICATION: Scan the components directory.
   - Identify similar components across feature directories (cards, lists, empty states).
   - Extract shared components into the shared component directory with configurable props.
   - Update all feature components to use shared primitives.
   - Ensure shared components use design tokens.

2. PATTERN EXTRACTION: Identify repeated UI patterns.
   - Form patterns: extract shared form wrappers. If a shared HOOK is needed, document the requirement and send to Teammate 3 — do NOT create hooks yourself.
   - List/table patterns: extract shared list components with sorting, filtering, pagination.
   - Modal/dialog patterns: unify modal usage.
   - Loading/empty/error state patterns: ensure all features use the same state components.

3. PROP INTERFACE CLEANUP: Review all component props.
   - Unify similar prop interfaces (e.g., standardize isLoading vs loading).
   - Remove unused props.
   - Add missing TypeScript types (no any).

4. FILE ORGANIZATION: Split 300+ line components. Follow CLAUDE.md directory conventions.

5. DESIGN TOKEN COMPLIANCE: Flag hardcoded colors, fonts, spacing values. Replace with design token references.

6. VERIFICATION: Run typecheck and component tests. Revert any change causing failures.

Report: components extracted/shared, patterns unified, props cleaned, test results (must be 100% pass).
```

## Teammate 3: hooks-and-logic-refactorer

Scope: Custom hooks, utilities, types, and shared logic.

Spawn prompt:

```
You are refactoring hooks, utilities, and shared logic for improved quality and maintainability.

CARDINAL RULE: No behavioral changes. Every existing test must still pass after your changes.

Read CLAUDE.md first. Check ./plancasting/tech-stack.md for the Session Language setting. Write all findings in that language. Then read ./plancasting/_audits/refactoring/plan.md for your assigned refactoring tasks.

Your tasks:

1. HOOK DEDUPLICATION: Scan the hooks directory.
   - Identify hooks with similar patterns (fetch list, handle loading, handle error, handle pagination with only the API call differing).
   - Extract generic parameterized hooks.
   - Keep domain-specific hooks as thin wrappers.

2. UTILITY CONSOLIDATION: Scan the lib directory.
   - Identify utility functions scattered across feature files.
   - Identify duplicated formatting, validation, or transformation functions.
   - Consolidate into shared utilities with consistent naming.

3. TYPE CONSOLIDATION: Scan all TypeScript types and interfaces.
   - Identify duplicated type definitions across features.
   - Consolidate shared types into a shared types file.
   - Ensure all components import from shared types.
   - Verify backend-generated types are used consistently.

4. IMPORT CLEANUP: Scan all files.
   - Remove unused imports.
   - Standardize import ordering (external -> internal -> relative).
   - Replace deep relative imports with path aliases.

5. DEAD CODE REMOVAL: Remove unused hook exports, utility functions, type definitions, and commented-out code.

6. VERIFICATION: Run typecheck and all tests. Revert any change causing failures.

Report: hooks refactored, utilities consolidated, types unified, dead code removed, test results (must be 100% pass).
```

## Teammate 4: test-and-structure-refactorer

Scope: Test quality, E2E tests, and overall project structure.

Spawn prompt:

```
You are refactoring tests and project structure for improved quality and maintainability.

CARDINAL RULE: Tests must continue to validate the same behaviors. You may restructure, deduplicate, and improve tests, but you must NOT remove test coverage.

Read CLAUDE.md first. Check ./plancasting/tech-stack.md for the Session Language setting. Write all findings in that language. Then read ./plancasting/_audits/refactoring/plan.md for your assigned refactoring tasks.

Your tasks:

1. TEST DEDUPLICATION: Scan all test directories.
   - Extract duplicated setup logic into shared test fixtures and helpers.
   - Create a fixtures directory for shared mock data and test utilities.
   - Consolidate tests that test the same behavior from different angles without reducing coverage.

2. TEST QUALITY: Review all test files.
   - Ensure descriptions follow "should [verb] when [condition]" format.
   - Ensure each test tests exactly one thing.
   - Verify Given-When-Then structure in acceptance criteria tests.
   - Add missing edge case tests.

3. E2E TEST OPTIMIZATION: Review E2E tests.
   - Consolidate overlapping tests into comprehensive journey tests.
   - Ensure page objects or helpers are used for repeated navigation.
   - Optimize execution time.

4. PROJECT STRUCTURE: Review directory structure.
   - Verify files are in correct directories per CLAUDE.md.
   - Verify naming conventions are consistent.
   - Ensure no circular dependencies exist.

5. TRACEABILITY AUDIT: Scan all files.
   - Verify PRD/BRD traceability header comments.
   - Add missing references where confidently verifiable. For uncertain mappings: // TODO: Verify traceability.
   - Verify assumption markers are still accurate.

6. VERIFICATION: Run all tests. Test count must be >= baseline.

Report: test helpers extracted, tests consolidated, structural fixes, traceability gaps fixed, final test count vs baseline.
```

## Coordination Protocol

- If backend-refactorer extracts a shared auth helper, notify hooks-and-logic-refactorer (hooks may call the old pattern).
- If frontend-component-refactorer extracts shared UI components, notify hooks-and-logic-refactorer (hook return types may need to match new component props).
- If hooks-and-logic-refactorer renames or moves a utility, notify frontend-component-refactorer and test-and-structure-refactorer (imports change).
- For shared-file conflicts: assign priority to the more structural change. The other teammate waits and adjusts after the first completes.
- After each teammate messages completion, immediately run `bun run typecheck && bun run test`. If tests fail, notify the responsible teammate before others proceed.
