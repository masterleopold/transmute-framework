# User Guide Generation (Mintlify) — Detailed Guide

## Why This Stage Exists

Stage 6D generates **internal documentation** (developer guide, API reference, architecture docs) stored in `docs/`. This stage generates **user-facing documentation** — how-to guides, getting started, FAQ, troubleshooting — as a standalone Mintlify site deployable to a `docs.yourproduct.com` subdomain.

Stage 7D runs AFTER Stage 7V because:
- The product must be verified-stable in production before documenting it
- The production URL is needed for navigation links and references
- Documenting a broken product wastes effort and produces misleading guides

**Stage Sequence**: ... -> 7V (Production Smoke Verification) -> **7D (this stage)** -> 8 (Feedback Loop) / 9 (Maintenance)

## Output Structure

**Multi-language** (session language differs from English):
```
user-guide/
├── docs.json                  # Root config (branding, theme, languages array)
├── en/                        # English (base language)
│   ├── docs.json              # English navigation config
│   ├── introduction.mdx
│   ├── quickstart.mdx
│   ├── journeys/              # DYNAMICALLY GENERATED from PRD user flows
│   │   ├── <journey-1>/
│   │   │   ├── <step-a>.mdx
│   │   │   └── <step-b>.mdx
│   │   └── <journey-N>/
│   ├── concepts/
│   │   └── <concept-N>.mdx
│   ├── api-reference/         # Conditional — only if product has public API
│   │   └── index.mdx
│   ├── faq.mdx
│   ├── troubleshooting.mdx
│   └── changelog.mdx
├── <session-lang>/            # Session language version — mirrors en/
│   ├── docs.json
│   └── (identical page structure, translated content)
├── images/
│   ├── landing-desktop.png
│   ├── dashboard-desktop.png
│   └── ...
├── public/
│   ├── logo.png
│   ├── logo-dark.png
│   └── favicon.png
└── snippets/
    ├── prerequisites.mdx
    └── support-cta.mdx
```

**English-only** (session language = English):
```
user-guide/
├── docs.json                  # Single config (branding + navigation combined)
├── introduction.mdx           # Content at ROOT level — no en/ subdirectory
├── quickstart.mdx
├── journeys/
│   └── <journey-N>/
├── concepts/
├── api-reference/             # Conditional
├── faq.mdx
├── troubleshooting.mdx
├── changelog.mdx
├── images/
│   ├── landing-desktop.png
│   └── ...
├── public/
└── snippets/
```

**Key difference**: For English-only, Mintlify expects content at the `./user-guide/` root (no `en/` subdirectory). The root `docs.json` contains BOTH branding configuration AND navigation. Placing content in `en/` without a `languages` config will cause pages to be unreachable.

## Mintlify Platform Reference

**Primary reference**: If the Mintlify Claude Code plugin is installed, use the `/mintlify:mintlify` skill (or read its reference files) for authoritative, up-to-date component syntax, configuration schema, navigation patterns, and API docs setup. The plugin also installs a Mintlify MCP server that teammates can query. The summary below covers essentials; defer to the plugin for detailed props, examples, and edge cases.

### Configuration

- Config file: `docs.json` (NOT `mint.json`)
- Schema: `"$schema": "https://mintlify.com/docs.json"`
- Required fields: `name`, `theme`, `colors.primary`, `navigation`
- 9 built-in themes: `mint`, `maple`, `palm`, `willow`, `linden`, `almond`, `aspen`, `luma`, `sequoia`
- Icons: Font Awesome, Lucide, or Tabler (configured via `icons.library` in docs.json)
- Static assets go in `public/` directory (files in `public/` are served at the URL root — e.g., `public/logo.png` → `/logo.png`). Screenshots and media go in `images/` at the docs root (e.g., `user-guide/images/` → served at `/images/...`). The `images/` directory is Mintlify's conventional static asset location for documentation media. Do NOT use `public/screenshots/` — Mintlify's monorepo mode may not correctly serve files from `public/` subdirectories, causing 403 errors on the CDN.
- Custom React components go in `snippets/` as `.jsx` files (no nested imports)
- Page references in navigation: use path without extension (e.g., `"guides/quickstart"` not `"guides/quickstart.mdx"`)

### Page Frontmatter

Every `.mdx` file starts with YAML frontmatter:
```yaml
---
title: "Page Title"           # Required — appears in nav and browser tab
description: "Brief overview"  # SEO snippet and nav preview. Should be 1-2 sentences summarizing page content for search indexing.
sidebarTitle: "Short Name"     # Shortened nav label (optional)
icon: "book"                   # Font Awesome/Lucide/Tabler icon
tag: "NEW"                     # Badge label for emphasis
mode: "default"                # Layout: default|wide|custom|frame|center
hidden: false                  # Hide from nav (URL still accessible)
deprecated: false              # Show deprecation warning
keywords: ["search", "terms"]  # Improve internal search
---
```

### Navigation Hierarchy

Valid structure: `tabs`, `anchors`, and `dropdowns` are **siblings** under `navigation` (NOT nested within each other). Each contains `groups` -> `pages`.
- Groups CAN nest within groups (a group's `pages` array can contain sub-group objects with their own `group`/`pages` — useful for collapsible subsections). Limit to ONE level of nesting — sub-groups inside sub-groups create confusing sidebar UX.
- Tabs, anchors, and dropdowns are parallel navigation containers — not a linear chain
- Each `group` has: `group` (name), `icon`, `tag`, `expanded` (boolean), `root` (landing page), `pages` (array — can contain page paths OR nested group objects)
- Each `tab` has: `tab` (name), `icon`, `pages` OR `items` (dropdown menus)
- Each `anchor` has: `anchor` (name), `icon`, `pages` — for top-level sidebar sections
- Each `dropdown` has: `dropdown` (name), `icon`, `pages` — expandable sidebar menus
- Global anchors (appear on all pages): `navigation.global.anchors`

### Built-in Components (globally available — no imports needed)

**Procedures**: `<Steps titleSize="p">` -> `<Step title="...">` — auto-numbered procedures with anchor links
**Callouts**: `<Note>`, `<Warning>`, `<Tip>`, `<Info>`, `<Check>`, `<Danger>` — each accepts `icon` and `color` (hex) props. Custom: `<Callout icon="key" color="#FFC107">`
**Cards**: `<Card title="..." icon="..." href="/path">` — clickable feature cards
**Tabs**: `<Tabs>` -> `<Tab title="...">` — content tabs with cross-page sync (disable with `sync={false}`)
**Accordions**: `<AccordionGroup>` -> `<Accordion title="..." defaultOpen={false}>` — collapsible FAQ-style
**Code**: `<CodeGroup dropdown={false}>` — multi-language code blocks with tab sync
**Frames**: `<Frame caption="...">` — centered content with borders. NOTE: Do NOT use `<Frame><img>` for screenshots — use markdown `![alt](/images/file.png)` syntax instead to avoid CDN 403 errors.
**Columns**: `<Columns cols={2}>` — responsive 1-4 column grid layout
**Tiles**: `<Tile href="..." title="..." description="...">` — clickable grid items (use with `<Columns>`)
**Changelog**: `<Update label="v1.0" description="..." tags={["feature"]}>` — changelog entries with RSS
**Tree**: `<Tree>` -> `<Tree.Folder name="...">` -> `<Tree.File name="...">` — file tree visualization
**Diagrams**: Mermaid fenced code blocks (triple-backtick mermaid) — flowcharts, sequence diagrams
**Badge**: `<Badge color="green" size="md" shape="pill">` — 13 colors, 4 sizes
**Prompt**: `<Prompt description="...">` — copyable AI prompts with Cursor integration (use for CLI commands or API examples)
**Panel**: `<Panel>` — right sidebar content panel (for supplementary info alongside main content)
**View**: `<View title="...">` — conditional content display (show/hide based on user selection)
**API fields**: `<ParamField path="name" type="string" required>` — parameter docs, `<ResponseField name="id" type="string">` — response docs, `<Expandable title="...">` — nested field groups (use in API reference pages)
**Snippet**: MDX import syntax — `import MySnippet from '/snippets/filename.mdx'` then `<MySnippet />` — include reusable content from `snippets/` directory. Supports props: `<MySnippet word="value" />`

### Multi-Language Configuration

Multi-language uses `navigation.languages` inside the root `docs.json`:

```json
{
  "navigation": {
    "languages": [
      {
        "language": "en",
        "name": "English",
        "isDefault": true,
        "groups": [
          { "group": "Getting Started", "pages": ["introduction", "quickstart"] }
        ]
      },
      {
        "language": "ja",
        "name": "Japanese",
        "groups": [
          { "group": "Getting Started", "pages": ["introduction", "quickstart"] }
        ]
      }
    ]
  }
}
```

The `navigation.languages` array defines per-language navigation directly in the root `docs.json`. Each language entry contains `groups` (and optionally `tabs`, `anchors`, `dropdowns`). Per-language `docs.json` files may still exist for navigation overrides but are no longer the primary pattern.

For per-language branding overrides (banner, footer, navbar), add a top-level `languages` array alongside `navigation`:
```json
{
  "languages": [
    { "language": "en", "banner": {}, "footer": {}, "navbar": {} },
    { "language": "ja", "banner": {}, "footer": {}, "navbar": {} }
  ],
  "navigation": {
    "languages": [...]
  }
}
```

**Multi-language**: Root `docs.json` has branding + `navigation.languages` with per-language groups. Per-language `docs.json` may still be used for navigation overrides.
**Single-language**: Root `docs.json` has BOTH branding AND navigation as `{ "groups": [...] }`. No per-language directories.

### API Playground (Conditional)

- Add OpenAPI spec: `"openapi": "openapi.json"` in root or tab-level config
- Tab config: `{ "tab": "API Reference", "icon": "square-terminal", "openapi": "openapi.json" }`
- Auto-generates interactive endpoint pages with request/response examples
- Display modes: `interactive` (default), `simple`, `none`
- Use `x-mint` extensions in OpenAPI spec for endpoint customization

### CLI Tools

- Install: `npm i -g mint` (rebranded from `@mintlify/cli` — the `mint` package is the current CLI)
- `mint dev` — local preview at localhost:3000. Options: `--port 3333`, `--no-open`. Requires Node.js v20.17.0+.
- `mint validate` — validate documentation builds without starting the server
- `mint broken-links` — check all internal links for broken references
- `mint a11y` — check documentation pages for accessibility issues
- `mint rename` — rename/move files and automatically update all references
- `mint upgrade` — upgrade from legacy `mint.json` to `docs.json` format
- One-off usage without global install: `npx mint dev` (or `bunx mint dev` if using Bun). The older `npx mintlify dev` (`@mintlify/cli` package) may also work but `mint` is the current CLI.

### Deployment

- Monorepo: Dashboard -> "Set up as monorepo" -> path `/user-guide` (no trailing slash)
- Auto-deploys via GitHub App on push to configured branch
- Preview deployments auto-created for PRs
- Custom domain: CNAME record `docs -> cname.mintlify-dns.com.` — HTTPS auto-provisioned
- If using CAA records: `0 issue "letsencrypt.org"`
- Canonical URL: `"canonicalUrl": "https://docs.yourproduct.com"` in docs.json
- Vercel alternative: `vercel.json` rewrites to `*.mintlify.app` for `/docs` subpath

## Known Failure Patterns

1. **PRD-as-docs copy**: Agent copies PRD specification text verbatim. PRD is for developers — user guides are for non-technical users. Rewrite completely in plain, task-oriented language.
2. **Feature-list organization**: Agent organizes docs by feature ID instead of user journey. Users think in tasks ("How do I deploy?"), not feature numbers.
3. **Missing navigation entries in docs.json**: Agent creates MDX files but forgets to add them to the `navigation` in per-language `docs.json`. Pages exist but are unreachable from the sidebar.
4. **Hardcoded branding placeholders**: Agent uses placeholder colors/logos instead of extracting from `plancasting/tech-stack.md` Design Direction section.
5. **Broken internal links**: MDX files link to pages that don't exist or use wrong paths. Mintlify uses paths relative to the language root directory, without file extensions.
6. **Jargon leakage**: Technical terms from PRD/BRD leak into user guides — "mutation," "query," "pipeline stage," "schema," "validator," "FEAT-007," "US-*," "SC-*," "FR-*," "BR-* (or BRL-*)," "UF-*." Use the product's user-facing terminology exclusively.
7. **Screenshots described but not captured**: Agent writes "see screenshot below" but never provides actual images. This stage solves this by capturing screenshots programmatically via Playwright MCP tools in Phase 1 step 8 — the lead captures all required screenshots before teammates start writing, and provides the screenshot manifest in `_guide-context.md`. Teammates reference only screenshots that exist in the manifest. Teammate 3 validates all `![](/images/...)` references point to actual files.
8. **docs.json syntax errors**: Invalid JSON in the Mintlify config file causes deployment failure. Always validate JSON syntax before finalizing. **CRITICAL**: Always run `npx mint validate` (or `bunx mint validate`) before committing docs.json — this catches schema errors that JSON parsing alone cannot detect (e.g., navigation structure, footer field names).
8a. **docs.json navigation must be an object, not an array**: The `navigation` field in `docs.json` must be an object containing `tabs`, `anchors`, or `dropdowns` — NOT a bare array of groups. A bare array `[{ "group": "...", "pages": [...] }]` will fail Mintlify's build validation. Correct: `{ "tabs": [{ "tab": "Guides", "groups": [{ "group": "...", "pages": [...] }] }] }`.
8b. **docs.json footer uses label/href, not name/url**: Footer link items require `label` and `href` fields, not `name` and `url`. Footer links must be nested: `{ "title": "Legal", "items": [{ "label": "Privacy", "href": "..." }] }`.
8c. **Duplicate h1 heading in MDX pages**: Mintlify auto-renders the frontmatter `title` as the page's h1 heading. If the MDX body ALSO starts with `# Title`, the title appears twice. NEVER include a `# Title` (h1) line in the MDX body when the frontmatter has a `title` field. Start the body with a paragraph or h2 (`##`) instead.
9. **llms.txt too shallow**: Ensure every page has a meaningful `description` in frontmatter — Mintlify auto-generates `llms.txt` from docs.json navigation + page frontmatter descriptions.
10. **Documenting incomplete features**: Cross-reference Stage 5B report — incomplete features must be "Coming Soon" or omitted.
11. **Translation inconsistency**: Translated version diverges structurally from English base. The session-language version MUST mirror the English structure exactly.
12. **Language config mismatch**: Root `docs.json` `languages` array doesn't match actual language directories on disk.
13. **Wrong config field**: Using `versions` for languages (should be `languages`), or `mint.json` filename (should be `docs.json`).
14. **Missing per-language docs.json**: Each language directory needs its own `docs.json` with complete navigation config. Without it, pages don't appear in the sidebar.
15. **Deeply nested groups**: Mintlify supports one level of group nesting, but nesting sub-groups inside sub-groups causes confusing sidebar UX. Limit to one level and use `anchors` for top-level organization.
16. **Screenshots show loading/skeleton state**: ALWAYS wait for data to settle using `browser_wait_for` with `text` (visible loaded content) or `textGone` (loading indicator disappeared). NEVER capture immediately after navigation.
17. **Screenshots expose test/seed data**: Use realistic-looking data or crop screenshots to exclude personal data.
18. **Screenshot paths and embed syntax**: Place screenshots in the `images/` directory at the docs root (e.g., `user-guide/images/`). Use **standard markdown syntax** for embedding: `![Alt text](/images/page-desktop.png)`. Do NOT use `<Frame><img src="..." /></Frame>` — this can cause 403 errors on Mintlify's CDN. Do NOT place images in `public/screenshots/` — Mintlify's monorepo mode may not serve files from `public/` subdirectories correctly. The `images/` directory at the docs root is the Mintlify convention. Also ensure `screenshots/` is not in `.gitignore` (a common pattern for E2E test screenshots that accidentally blocks user-guide images too — add `!user-guide/images/` exception if needed).
19. **Too many screenshots per page**: Limit to 1-3 per guide page: hero/overview shot + 1-2 key interaction shots. Use text descriptions for intermediate steps.
20. **Zero screenshots deployed**: Agent sets screenshot mode to `text-only` because authenticated page login fails, even though public pages (landing, signup, pricing, help) are fully capturable without auth. The result is a documentation site with NO visual context. ALWAYS capture public page screenshots first. Auth failure only blocks authenticated page screenshots. See Phase 1 Step 8g tiered failure handling.
21. **Mintlify build validation not run before commit**: Agent generates docs.json with schema errors (wrong navigation structure, wrong footer field names) that only surface when Mintlify tries to build, causing repeated deployment failures. ALWAYS run `npx mint validate` (or `bunx mint validate`) in the `user-guide/` directory before committing.
22. **Dollar signs rendered as LaTeX math**: MDX interprets `$...$` as inline LaTeX math. Any `$` followed by a number (e.g., `$69`, `$149`) will be parsed as a math expression, producing garbled output. ALWAYS escape dollar signs before numbers with a backslash: `\$69`, `\$149`. This affects pricing tables, cost comparisons, and any mention of currency amounts.

## Detailed Agent Team Architecture

### Pre-Generation Cleanup Safety Protocol

If `./user-guide/` already exists from a prior run:
1. Run `git status ./user-guide/` and `git diff ./user-guide/` to detect both uncommitted and staged changes.
2. If uncommitted, unstaged, or untracked changes exist, STOP — do not proceed. Report: "user-guide/ has uncommitted changes. Commit or discard them before re-running Stage 7D."
3. If `./plancasting/_audits/visual-polish/design-plan.md` exists (6P-R was run), record image paths before deletion: `grep -r 'src="' user-guide/ --include='*.mdx' > /tmp/7d-prior-image-paths.txt 2>/dev/null || true`. This file is used in step 4 below for screenshot path alignment.
4. Only delete after explicit operator confirmation or after verifying zero uncommitted changes.

### Stale Context Detection

If `_guide-context.md` already exists (retained from a prior FAIL'd run): read it first. If PRD files have been modified since the prior run (check `git diff` on `plancasting/prd/`), regenerate the content map from scratch rather than reusing stale context. Otherwise, reuse the content map and branding sections, then update only the screenshot mode and manifest fields.

### Teammate 1: "journey-writer"

Writes all journey guide pages + introduction + quickstart.

For EACH journey page:
1. Read source UF-* flow — extract happy path steps
2. Read source SC-* screen specs — extract visible UI labels, layout zones
3. Read source US-* stories — extract acceptance criteria for callouts
4. Read relevant BR-* (or BRL-*) — extract plan-tier restrictions and validation rules

Write:
- Frontmatter: title (user's goal), description, icon, sidebarTitle
- **NEVER start the body with a `# Title` heading** — Mintlify auto-renders the frontmatter `title` as the page's h1. Adding `# Title` in the body creates a duplicate. Start with a paragraph or `##` subheading.
- Opening paragraph: what the user wants to accomplish and why
- **Hero visual** (check manifest for recordings first, then screenshots):
  - If an animated recording (MP4) exists for this page in the manifest `Recordings` section, embed with a `<video>` tag — this REPLACES the static screenshot:
    ```mdx
    <video autoPlay muted loop playsInline className="w-full aspect-video rounded-xl" src="/images/signup-flow.mp4"></video>
    ```
  - If NO recording exists but a static screenshot does, use standard markdown image syntax:
    ```mdx
    ![Project dashboard with active projects listed](/images/dashboard-desktop.png)
    ```
  - **IMPORTANT**: Use markdown `![alt](/images/file.png)` syntax for screenshots — NOT `<Frame><img src="..." /></Frame>`. The Frame+img pattern can cause 403 CDN errors on Mintlify's hosting. Standard markdown images work reliably.
  - **IMPORTANT**: Do NOT embed both a recording AND a static screenshot for the same page. The video's first frame serves as the static visual.
- Step-by-step instructions using `<Steps>`/`<Step>` components
- Step screenshots (if in manifest) within relevant `<Step>`, using markdown `![alt](/images/file.png)` syntax
- `<Note>` callouts for "what you should see" at key steps
- `<Tip>` callouts for shortcuts and best practices
- `<Info>` callouts for plan-tier restrictions
- `<Warning>` callouts for validation rules
- "Next steps" section linking to next logical journey page
- Desktop/mobile screenshot tabs using `<Tabs>` if both viewports available:
  ```mdx
  <Tabs>
    <Tab title="Desktop">
      ![Dashboard desktop view](/images/dashboard-desktop.png)
    </Tab>
    <Tab title="Mobile">
      ![Dashboard mobile view](/images/dashboard-mobile.png)
    </Tab>
  </Tabs>
  ```
- NEVER reference a screenshot not in the manifest. If SKIPPED, use `<Note>` text description.
- If `text-only` mode: use `<Note>` callouts for ALL pages instead of images.
- **ALWAYS escape dollar signs before numbers** — MDX interprets `$...$` as LaTeX math. Write `\$69`, `\$149`, NOT `$69`, `$149`. This applies to ALL currency amounts in pricing tables, cost comparisons, and inline text.

Also write: `introduction.mdx` (welcome + product overview + `<Card>` navigation) and `quickstart.mdx` (shortest path from signup to first meaningful action).

If multi-language: English first under `en/`, then translate to session language. Identical page structure.
If English-only: generate directly under `user-guide/` root (no `en/` subdirectory).

Component usage: `<Steps>`/`<Step>` for procedures (NEVER numbered markdown lists), `<Note>`/`<Warning>`/`<Tip>`/`<Info>` for callouts (NEVER blockquotes), `<Card>` for feature highlights, `<Tabs>` for alternatives (desktop/mobile, plan tiers), `<AccordionGroup>` for in-page FAQs, `<Accordion>` for optional/advanced content, markdown `![alt](/images/file.png)` for screenshots, `<Columns>` with `<Tile>` for next steps, MDX imports for reusable snippets.

### Teammate 2: "concepts-and-reference-writer"

1. **Concept pages** (`concepts/`): Clear, jargon-free explanations from product overview and glossary. Use Mermaid diagrams where helpful. Use `<Accordion>` for deeper explanations.

2. **FAQ** (`faq.mdx`): Extract questions from acceptance criteria and business rules. Structure as `<AccordionGroup>` with `<Accordion>`. Group by topic.

3. **Troubleshooting** (`troubleshooting.mdx`): Derive from 7V report, 6V report, and interaction patterns. Structure as problem -> cause -> solution with `<Steps>`.

4. **Changelog** (`changelog.mdx`): Derive from release plan or feature map. Use `<Update>` components with user-facing descriptions.

5. **API Reference** (conditional): Skip if no public API. Skip manual pages if OpenAPI spec exists (Teammate 3 configures auto-generation). Write manual pages from `plancasting/prd/12-api-specifications.md` using `<ParamField>`, `<ResponseField>`, `<Expandable>` if needed.

**Visual embedding**: First check the `Screenshot mode` field in `_guide-context.md` — if `text-only`, skip ALL visual embedding and use `<Note>` callouts instead. If mode is `images` or `images-partial`: check BOTH the `Recordings` section (MP4 videos) and the screenshot manifest. If an animated recording exists for a page, use `<video autoPlay muted loop playsInline className="w-full aspect-video rounded-xl" src="/images/<name>.mp4"></video>` INSTEAD of a static screenshot (recordings replace screenshots, never alongside). If no recording exists, use markdown syntax: `![Alt text](/images/file.png)`. NEVER reference a media file that is NOT in the manifest.

**ALWAYS escape dollar signs before numbers** — MDX interprets `$...$` as LaTeX math. Write `\$69`, `\$149`, NOT `$69`, `$149`. This applies to ALL currency amounts in pricing tables, FAQ answers, and inline text.

**NEVER start the body with a `# Title` heading** — Mintlify auto-renders the frontmatter `title` as the page's h1. Start with a paragraph or `##` subheading.

### Teammate 3: "config-and-structure"

1. **Root docs.json**: Branding config with product name, theme, logo, colors, navbar, search, feedback, canonical URL. For multi-language, use `navigation.languages` pattern inside the root `docs.json`. For English-only, include navigation as `{ "groups": [...] }`.

   Use this VALIDATED template as the starting point (adapt names, colors, and pages):
   ```json
   {
     "$schema": "https://mintlify.com/docs.json",
     "theme": "mint",
     "name": "Product Name",
     "logo": { "light": "/logo-light.svg", "dark": "/logo-dark.svg" },
     "favicon": "/favicon.svg",
     "colors": { "primary": "#0891b2", "light": "#22d3ee", "dark": "#0891b2" },
     "navigation": {
       "languages": [
         {
           "language": "en",
           "name": "English",
           "isDefault": true,
           "groups": [
             { "group": "Getting Started", "pages": ["introduction", "quickstart"] }
           ]
         }
       ]
     }
   }
   ```

   DO NOT add: `colors.anchors`, top-level `anchors` array, top-level `languages` array, or `navigation` as a bare array.

2. **Per-language docs.json** (multi-language only): Navigation with anchors -> groups -> pages hierarchy (Guides, Concepts, Help anchors + conditional API Reference tab). Per-language `docs.json` files may still be used for navigation overrides, but the primary navigation is defined via `navigation.languages` in the root `docs.json`.

3. **Static assets** (`public/`): Copy product logo, create favicon.

4. **Snippets**: `prerequisites.mdx` and `support-cta.mdx`.

5. **Validation** (BLOCKED until Teammates 1 and 2 complete):
   **a. Structure & link validation** — prefer Mintlify CLI (`npx mint`):
   - `mint validate` — catches invalid docs.json, missing nav pages, build errors
   - `mint broken-links` — catches broken internal links
   - `mint a11y` — catches accessibility issues
   If CLI unavailable, validate manually (JSON parsing, page existence, orphan check, link check).

   **b. Content quality checks** (always manual):
   - Scan ALL MDX files for jargon leakage. Two categories:
     i. **Always flag** (technical/framework identifiers): PRD/BRD specification IDs (FEAT-, US-, SC-, FR-, BR-, BRL-, UF-), pipeline terminology ("pipeline stage", "stage 5"), technical database terms ("schema", "validator", "mutation", "query" in database context)
     ii. **Flag with context** (common words that MAY be jargon): "action", "workflow" — only flag in technical context (e.g., "Convex action"), NOT in general usage (e.g., "take action")
   - Verify every image reference in MDX files (markdown `![](/images/...)` syntax) points to an actual file in `user-guide/images/`. Broken media paths cause visible broken images in the deployed docs site.
   - Verify every page has a meaningful `description` in frontmatter
   - If multi-language: verify identical directory structure and page count

## Screenshot Capture Process

### Manifest Generation

Map each journey page to specific screenshots:

| ID | Journey Page | URL | Auth | Entity State | Viewport | Wait For | Filename |
|----|-------------|-----|------|-------------|----------|----------|----------|
| SS-001 | quickstart | / | none | -- | 1440x900 | landing hero visible | landing-desktop.png |
| SS-002 | quickstart | / | none | -- | 375x812 | landing hero visible | landing-mobile.png |

### Capture Rules

- **Viewports**: Desktop (1440x900) for ALL pages. Mobile (375x812) for key pages only (max 5 mobile screenshots). `browser_resize` requires BOTH `width` AND `height` — always provide both values. Capture viewport-only screenshots (NOT full-page) — full-page captures of long pages produce unwieldy tall images.
- **Screenshot budget**: Maximum 30 total.
- **Wait for content**: ALWAYS wait for data to load. Use `browser_wait_for` with `text` (visible loaded content) or `textGone` (loading text to disappear). NEVER capture while loading spinners are visible.
- **Hide UI overlays**: ALWAYS hide development and compliance overlays before capturing. Inject CSS via `browser_evaluate` to hide Next.js dev indicator badge, cookie consent banners, and other fixed-position dev/debug overlays:
  ```javascript
  const style = document.createElement('style');
  style.textContent = 'nextjs-portal, [data-nextjs-dialog-overlay], [data-nextjs-toast], [class*="cookie" i], [id*="cookie" i], [class*="consent" i], [id*="consent" i] { display: none !important; }';
  document.head.appendChild(style);
  document.querySelectorAll('nextjs-portal').forEach(el => el.remove());
  ```
  Also click "Accept All" on any cookie banner to dismiss it before capture.
- **Dark mode** (optional): 3-5 key screens with `-dark` suffix if dark mode is a selling point.
- **Verify before committing**: After capturing each screenshot, visually verify it shows actual content — NOT loading spinners, "Session expired" screens, error boundaries, blank pages, cookie banners, or dev badges. If any of these appear, retry with longer wait times, overlay hiding, or switch capture targets.

### Capture Process

1. **Public pages first** (no auth): Navigate, resize viewport (both width AND height), wait for content, hide overlays, capture.
2. **Authenticated pages**: Read `./e2e/constants.ts` for test credentials. Use `browser_navigate` to login page, use `browser_snapshot` to get element refs, then `browser_fill_form` (with `ref` values) or `browser_click`/`browser_type` to log in. Navigate to each authenticated route. For entity-state-dependent pages, navigate to an entity in the correct state. Resize + wait + capture at each viewport.
3. **Element-level screenshots** (optional, max 5): Inject temporary CSS highlight via `browser_evaluate`, capture, remove highlight. Use sparingly.

### Save Location

All screenshots to `./user-guide/images/`. If the project's `.gitignore` contains `screenshots/` (common for E2E test artifacts), add `!user-guide/images/` exception to ensure doc images are tracked by git. Verify with `git ls-files user-guide/images/` after staging.

If `browser_take_screenshot` supports a `filename` parameter, use it (e.g., `filename: "./user-guide/images/dashboard-desktop.png"`). If not, use `browser_evaluate` to trigger `page.screenshot({ path: '...' })` via Playwright's page API, or save the returned data using a file-write tool.

Naming: `<page-slug>-<viewport>.png`, dark mode: `<page-slug>-<viewport>-dark.png`, element highlights: `<page-slug>-<element>-highlight.png`.

### Tiered Failure Handling

**Tier 1 — Public pages (MUST capture, no auth required)**:
Public pages (landing, login, signup, pricing, help, terms, privacy) require NO authentication. These screenshots MUST be captured regardless of auth status. If ANY public page fails to load, investigate (DNS, SSL, server error) before skipping. Public page screenshot failure is a BLOCKER.

**Tier 2 — Authenticated pages (best-effort, PRODUCTION FIRST)**:
- ALWAYS attempt production first for authenticated captures — production builds handle auth correctly
- Login succeeds on production -> capture all authenticated screenshots
- Login fails on production -> try dev server login as fallback. BUT: if dev server shows "Session expired" on dashboard/settings after successful login redirect, this is a dev-mode auth race condition (NOT a credentials issue). Switch back to production and investigate the login failure there.
- Login fails on both -> mark individual authenticated screenshots as "SKIPPED — auth login unavailable" in the manifest. Do NOT set entire mode to `text-only`.
- **Common auth pitfall**: The login form may succeed (URL redirects to /dashboard) but the page shows "Session expired" because the real-time auth provider's token fetch was aborted during the hard navigation. This is a dev-mode-only issue. If this happens, ALWAYS try production URL before giving up.

**Tier 3 — Overall mode decision**:
- Tier 1 (public) screenshots ALL succeed -> set mode to `images` regardless of Tier 2 results
- Some Tier 2 (authenticated) screenshots skipped -> set mode to `images-partial` and note which pages lack screenshots
- ONLY set `text-only` if production URL AND dev server are BOTH completely inaccessible

### Animated Recordings (optional enhancement)

If the project has Playwright recording scripts at `./e2e/doc-recordings/`, capture animated screen recordings for interactive flows. Animated recordings provide significantly better visual context than static screenshots for form filling, navigation, and toggle interactions. When a page has an animated recording, it REPLACES the static screenshot (do not show both).

**Prerequisites**:
- `ffmpeg` installed (`brew install ffmpeg` on macOS)
- Playwright browsers installed (`npx playwright install --with-deps chromium`)
- A standalone Playwright config at `./e2e/doc-recordings/playwright.recordings.config.ts` (skips globalSetup and webServer — recordings target production or dev URL directly)

**Recording architecture**:
- `record-flows.spec.ts` — Public pages (landing, signup, login, pricing, help, forgot-password). No auth needed. Always succeeds.
- `record-auth-flows.spec.ts` — Authenticated pages (dashboard, project detail, settings, billing). Requires valid credentials.
- Each test enables `video: "on"` in the Playwright context, which records a WebM file for the entire test duration.
- After recording, `convert-recordings.sh` converts WebM -> MP4 (primary, H.264 CRF 28) and GIF (fallback).

**Running recordings**:
```bash
# Public pages (always use production URL)
PLAYWRIGHT_BASE_URL=https://your-production-url.com \
  bunx playwright test --config=e2e/doc-recordings/playwright.recordings.config.ts \
  e2e/doc-recordings/record-flows.spec.ts

# Auth pages (MUST use production URL — dev server has auth race conditions)
TEST_EMAIL=user@example.com TEST_PASSWORD=password \
PLAYWRIGHT_BASE_URL=https://your-production-url.com \
  bunx playwright test --config=e2e/doc-recordings/playwright.recordings.config.ts \
  e2e/doc-recordings/record-auth-flows.spec.ts

# Convert WebM to MP4/GIF
./e2e/doc-recordings/convert-recordings.sh
```

**CRITICAL — Auth recordings MUST target production**: Dev servers (Next.js dev mode) have a known race condition where the first `POST /api/auth/token` gets `net::ERR_ABORTED` during navigation, causing React error boundaries to permanently show "Session expired". This does NOT happen in production builds. Always use the production URL for authenticated recordings. The conversion script trims the first ~10 seconds (login/navigation) from auth recordings using `ffmpeg -ss`.

**Overlay hiding**: Both recording scripts inject CSS to hide Next.js dev badge, cookie consent banners, and other overlays via a `hideOverlays()` function called after each `page.goto()`. This uses `page.addStyleTag()` with selectors targeting `nextjs-portal`, `[class*="cookie" i]`, `[class*="consent" i]`, etc. The overlays are hidden from the FIRST frame of the recording.

**Embedding in MDX**:
```mdx
<video autoPlay muted loop playsInline className="w-full aspect-video rounded-xl" src="/images/<name>.mp4"></video>
```
- When a page has an animated recording, use the `<video>` tag INSTEAD of the static `![alt](/images/...)` screenshot — not alongside it. The video replaces the screenshot.
- Mintlify fully supports `<video>` HTML tags in MDX. Use camelCase attributes (`autoPlay`, `playsInline`).
- The MP4 format is preferred (smaller, higher quality). GIF is a fallback for markdown-only contexts.

**Budget**:
- Maximum 1 animated recording per page
- Keep each recording 5-15 seconds
- MP4 under 1MB, GIF under 2MB
- For oversized GIFs: reduce fps (`fps=6`), scale (`scale=480:-1`), or trim duration (`-t 10`)

**Failure handling**:
- If `ffmpeg` is not available -> skip recordings, use static screenshots
- If public recordings fail -> investigate (DNS, server error) before skipping
- If auth recordings fail (login fails) -> use static screenshots for auth pages, recordings for public pages
- If auth recordings show "Session expired" -> switch to production URL (dev server race condition)
- A mix of recordings (public) + screenshots (auth) is acceptable

**Manifest update**: Add a `Recordings` section to the screenshot manifest in `_guide-context.md` listing available MP4 files. Teammates check this manifest before embedding — if a recording exists for a page, use `<video>` instead of `![screenshot]`.

## Report Template

Generate `./plancasting/_audits/user-guide/report.md`:

```markdown
# User Guide Generation Report — Stage 7D

## Summary
- **Generation Date**: [date]
- **Production URL**: [url]
- **Mintlify Theme**: [theme]
- **Languages**: [list]
- **Total Pages**: [n] (per language)

## Structure Validation
- Root docs.json: VALID / INVALID ([error])
- Per-language docs.json: VALID / INVALID / N/A (English-only)
- Navigation entries: [n] pages configured
- Orphan pages: [n] ([list])
- Missing pages: [n] ([list])

## Content Coverage
- User flows documented: [n]/[total] ([%])
- P0 features covered: [n]/[total]
- P1 features covered: [n]/[total]
- P2 features mentioned: [n]/[total]
- Incomplete features (from 5B) marked "Coming Soon": [n]

## Screenshot Coverage
- Screenshot mode: images / images-partial / text-only
- Screenshots in manifest: [n]
- Successfully captured: [n]
- Skipped: [n] — [list]
- Capture target: Production URL / Dev server
- Desktop screenshots: [n]
- Mobile screenshots: [n]
- Animated recordings (MP4): [n] ([list — public vs auth])
- Pages with embedded visuals: [n]/[total journey pages] (screenshots: [n], recordings: [n])
- Broken media references: [n] ([list — image/video references pointing to non-existent files])
- Total media size: [n] MB

## Jargon Scan
- Technical terms found: [n] ([list with file and line])
- PRD/BRD identifiers found: [n] ([list])

## Link Integrity
- Internal links checked: [n]
- Broken links: [n] ([list])

## Translation Parity (if multi-language)
- en/ page count: [n]
- <session-lang>/ page count: [n]
- Structure match: YES / NO ([differences])

## Mintlify CLI Checks
- mint validate: PASS / FAIL / NOT TESTED
- mint broken-links: PASS / FAIL / NOT TESTED
- mint a11y: PASS / FAIL / NOT TESTED
- Local preview: VERIFIED / NOT TESTED

## Gate Decision
- PASS / WARN / FAIL
```

## Gate Decision Criteria

| Decision | Criteria |
|---|---|
| **PASS** | All P0/P1 features documented, zero jargon leakage, zero broken links, all docs.json files valid, all navigation entries resolve, translation parity (if multi-language), CLI checks pass (or N/A if CLI unavailable) |
| **WARN** | P0/P1 fully covered but: P2 coverage gaps, minor style inconsistencies, 1-2 jargon instances in non-critical pages, orphan pages (MDX files not in any navigation), minor `mint a11y` issues, or Mintlify CLI checks not tested (CLI unavailable). Deploy with known issues documented. |
| **FAIL** | Any of: missing P0/P1 feature coverage, broken navigation (pages in nav but no file), invalid docs.json, >=3 jargon instances, translation structure mismatch, broken media references (image/video references pointing to non-existent files). Fix before deploying. |

## Content Generation Rules

For each guide page, follow this transformation pipeline:

1. **Identify the user flow** (from `plancasting/prd/06-user-flows.md`):
   - Extract the happy path steps
   - Extract entry points and exit points

2. **Enrich with screen specs** (from `plancasting/prd/08-screen-specifications.md`):
   - For each step, find the matching SC-* screen spec
   - Use visible labels (button text, field labels) instead of component names

3. **Add acceptance criteria** (from `plancasting/prd/04-epics-and-user-stories.md`):
   - Transform "Given/When/Then" into "What you should see" `<Note>` callouts

4. **Apply business rules** (from `plancasting/brd/14-business-rules-and-logic.md`):
   - Plan-tier restrictions -> `<Info>` callouts ("This feature requires the Pro plan")
   - Validation rules -> `<Warning>` callouts ("Maximum 10 items per project on the Starter plan")

5. **Embed visuals** (from the manifest in `_guide-context.md`):
   - First check the screenshot mode field — if `text-only`, skip ALL visual embedding and use `<Note>` callouts instead
   - Check the `Recordings` section of the manifest first — if an MP4 recording exists for this page, embed with `<video autoPlay muted loop playsInline className="w-full aspect-video rounded-xl" src="/images/<name>.mp4"></video>` INSTEAD of a static screenshot (do NOT show both)
   - If no recording exists, check the screenshot manifest — embed with `![alt](/images/file.png)` markdown syntax
   - Place the hero visual after the opening paragraph, before the first `<Steps>` block
   - Place step-level screenshots inside the relevant `<Step>` element
   - If no visual exists for this page, use `<Note>` callouts describing what the user should see

6. **Rewrite for the audience**:
   - Replace ALL technical terms with user-facing language
   - Use the product's terminology from `plancasting/prd/18-glossary-and-cross-references.md`
   - Write in second person ("you"), present tense, imperative mood for instructions

## Cross-Stage References

- **If 7V FAIL**: Do NOT run this stage.
- **After generating**: Push to trigger Mintlify auto-deploy.
- **UI changes after 7D**: Stage 8 test-and-docs-updater updates `./user-guide/`. If UI changes affect screenshotted/recorded pages, recapture the affected media:
  - For screenshots: re-run Phase 1 step 8 with a filtered manifest (only the changed pages)
  - For animated recordings: re-run `bunx playwright test --config=e2e/doc-recordings/playwright.recordings.config.ts` for the affected spec files, then `./e2e/doc-recordings/convert-recordings.sh` to reconvert
- **Stage 8 integration**: "Documentation" feedback category routes to updating the Mintlify site.
- **Stage 9 integration**: If dependency updates change UI, re-verify affected journey pages.
- **Re-running 7D**: Idempotent — deletes and recreates `./user-guide/` from current PRD state. Before deletion, verify no custom content was manually added — use `git diff ./user-guide/` to check.

## Stack Adaptation Notes

- **Screenshot embedding**: Use markdown `![alt](/images/file.png)` syntax. Do NOT use `<Frame><img>` wrapping.
- **Mintlify config**: `docs.json` at docs root. For monorepo setup, set the Mintlify dashboard path to `/user-guide`.
- **Images directory**: `user-guide/images/` (served at `/images/...`). NOT `public/screenshots/`.
