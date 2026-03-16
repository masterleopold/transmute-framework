---
description: Template for frontend rules — component states, hook data mapping, responsive behavior, design tokens, and image optimization for the frontend framework.
globs: ["[FRONTEND_DIR]/**"]
---

# Frontend Rules

> **This is a template.** Stage 3 (Scaffold Generation) reads this template and generates `.claude/rules/frontend.md` with actual project values. Stage 3 MUST: (1) replace ALL `[BRACKETED]` placeholder markers (e.g., `[FRONTEND_DIR]`, `[LOADING_COMPONENT]`), (2) replace each `<!-- TODO -->` HTML comment with a proper `<!-- Source: Stage 3 | Evidence: [ref] | Confidence: HIGH -->` annotation (`// TODO:` inside code blocks are code example placeholders — replace those with actual code patterns), and (3) update the globs in frontmatter with actual paths. Stage 4 confirms replacements are complete. After Stage 3 renders this template, verify no placeholders remain: `grep -n '\[.*\]' .claude/rules/frontend.md` — the output should be empty (all `[BRACKETED]` markers replaced with actual values). Do not edit this template directly.

## Component States

<!-- Source: Stage 3 | Evidence: tech-stack.md | Confidence: HIGH -->

- Per CLAUDE.md Part 1 Component Rules #1, every component must handle all five states (default, loading, empty, error, disabled). For data-fetching components, use `[LOADING_COMPONENT]` for loading states and `[ERROR_COMPONENT]` for error states (include a retry action where appropriate); never render a blank screen.
- Empty states must have a descriptive message and, where applicable, a call-to-action.

```typescript
// TODO: Replace with actual state handling pattern for [FRONTEND_FRAMEWORK]
// if (isLoading) return <[LOADING_COMPONENT] />;
// if (error) return <[ERROR_COMPONENT] error={error} onRetry={refetch} />;
// if (!data || data.length === 0) return <[EMPTY_COMPONENT] />;
```

## Hook Data Shapes

<!-- TODO: Stage 3 — replace with actual hook pattern. Source: tech-stack.md | Confidence: HIGH -->

- Never cast backend responses with `as unknown as Type` — create explicit mapping functions when shapes differ; co-locate response types with hooks.
- When a backend field is renamed or computed, map it explicitly and document the mapping with a comment in the hook.

```typescript
// TODO: Replace with actual hook mapping pattern
// function mapResponse(raw: BackendResponse): FrontendType {
//   return { id: raw._id, name: raw.title, ... };
// }
```

## Responsive Behavior

<!-- TODO: Stage 3 — replace with actual breakpoint system -->

- Use the project's breakpoint system (`[BREAKPOINT_CONFIG]`) — never hardcode pixel widths; write base styles mobile-first, then layer larger breakpoints.
- Test all pages at 320px, 768px, 1024px, and 1440px minimum.
- Navigation must collapse to a mobile-friendly pattern below `[MOBILE_BREAKPOINT]`.

## Design Tokens

<!-- TODO: Stage 3 — replace [DESIGN_TOKENS_PATH] with actual path (e.g., src/styles/design-tokens.ts, src/tokens/colors.css). All components import from this single source. -->
<!-- Note: Stage 3 creates the design-tokens file based on the design direction from `plancasting/tech-stack.md`. If Stage 0 did not provide a design direction, Stage 3 creates a minimal placeholder that Stage 5 can extend when building the first frontend component. -->

- Import all colors, spacing, typography, and shadows from `[DESIGN_TOKENS_PATH]` — never hardcode color or spacing values in component files; use the token scale.
- If a new token is needed, add it to the design tokens file, not inline.

## Image Optimization

<!-- TODO: Stage 3 — replace with actual image component -->

- Use `[IMAGE_COMPONENT]` for all images — never use raw `<img>` tags; always specify `width`/`height` or use `fill` with a sized container.
- Provide `alt` text for all images (empty `alt=""` only for purely decorative images) and use appropriate formats: WebP/AVIF for photos, SVG for icons and illustrations.

## Accessibility

<!-- TODO: Stage 3 — replace with actual ARIA and keyboard patterns for [FRONTEND_FRAMEWORK] -->

- Per CLAUDE.md Part 1 Component Rules #2 and #3, all interactive elements must have appropriate ARIA attributes and support keyboard navigation — use semantic HTML first, add ARIA only when native semantics are insufficient.
- Tab order follows visual order, focus is trapped in modals, Escape closes overlays.

## Icon Usage

<!-- TODO: Stage 3 — replace [ICON_LIBRARY] and [ICON_REGISTRY_PATH] with actual values from tech-stack.md -->

- Per CLAUDE.md Part 1 Component Rules #6, never use inline SVG `<path>` elements for standard UI icons — import all icons from `[ICON_REGISTRY_PATH]`; inline SVGs are permitted only for product logos, brand marks, or custom illustrations.
- When adding a new icon, register it in `[ICON_REGISTRY_PATH]` first; import from there, not directly from `[ICON_LIBRARY]` in component files.
