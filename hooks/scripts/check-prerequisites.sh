#!/usr/bin/env bash
# Transmute Framework — Gate Enforcement Hook
# Validates that prerequisites from prior stages exist before allowing
# the next stage to proceed. Reads the skill name from stdin (tool_input JSON).

set -euo pipefail

# Read the tool input from stdin
INPUT=$(cat)

# Extract the skill name from the JSON input (macOS-compatible — no grep -P)
SKILL_NAME=$(echo "$INPUT" | sed -n 's/.*"skill"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)

# If we can't extract the skill name, pass through
if [[ -z "$SKILL_NAME" ]]; then
  exit 0
fi

# Define prerequisite checks for each stage
case "$SKILL_NAME" in
  tech-stack)
    # Stage 0: Requires business plan
    if [[ ! -d "./plancasting/businessplan" ]]; then
      echo "BLOCK: Stage 0 (Tech Stack) requires a Business Plan at ./plancasting/businessplan/. Place your business plan files there first."
      exit 1
    fi
    ;;

  brd)
    # Stage 1: Requires business plan and plancasting/tech-stack.md
    if [[ ! -d "./plancasting/businessplan" ]]; then
      echo "BLOCK: Stage 1 (BRD) requires a Business Plan at ./plancasting/businessplan/. Place your business plan files there first."
      exit 1
    fi
    if [[ ! -f "./plancasting/tech-stack.md" ]]; then
      echo "BLOCK: Stage 1 (BRD) requires plancasting/tech-stack.md from Stage 0. Run '/transmute:cast tech-stack' first."
      exit 1
    fi
    ;;

  prd)
    # Stage 2: Requires BRD
    if [[ ! -d "./plancasting/brd" ]]; then
      echo "BLOCK: Stage 2 (PRD) requires ./plancasting/brd/ from Stage 1. Run '/transmute:cast brd' first."
      exit 1
    fi
    ;;

  validate-specs)
    # Stage 2B: Requires BRD + PRD
    if [[ ! -d "./plancasting/brd" ]] || [[ ! -d "./plancasting/prd" ]]; then
      echo "BLOCK: Stage 2B (Spec Validation) requires both ./plancasting/brd/ and ./plancasting/prd/. Run Stages 1 and 2 first."
      exit 1
    fi
    ;;

  scaffold)
    # Stage 3: Requires spec validation report + credentials
    if [[ ! -f "./plancasting/_audits/spec-validation/report.md" ]]; then
      echo "BLOCK: Stage 3 (Scaffold) requires spec validation report. Run '/transmute:cast validate' first."
      exit 1
    fi
    # Check for credential placeholders
    if [[ -f ".env.local" ]]; then
      if grep -qE 'YOUR_.*_HERE|TODO_.*|CHANGE_ME|PLACEHOLDER|^[A-Z_]+=\s*$' .env.local 2>/dev/null; then
        echo "BLOCK: Stage 3 requires all credentials in .env.local to be real values. Fix placeholders first."
        exit 1
      fi
    fi
    ;;

  implement)
    # Stage 5: Requires scaffold
    if [[ ! -f "./plancasting/_scaffold-manifest.md" ]] && [[ ! -f "./ARCHITECTURE.md" ]]; then
      echo "BLOCK: Stage 5 (Implementation) requires scaffold from Stage 3. Run '/transmute:cast scaffold' first."
      exit 1
    fi
    ;;

  audit-completeness)
    # Stage 5B: Requires implementation
    if [[ ! -f "./plancasting/_progress.md" ]]; then
      echo "BLOCK: Stage 5B (Audit) requires plancasting/_progress.md from Stage 5. Run '/transmute:cast implement' first."
      exit 1
    fi
    ;;

  audit-security|audit-a11y|optimize)
    # Stage 6A/6B/6C: Requires 5B report
    if [[ ! -f "./plancasting/_audits/implementation-completeness/report.md" ]]; then
      echo "BLOCK: This stage requires the implementation completeness audit. Run '/transmute:cast audit' first."
      exit 1
    fi
    ;;

  refactor)
    # Stage 6E: Requires 6A-6C complete
    if [[ ! -f "./plancasting/_audits/implementation-completeness/report.md" ]]; then
      echo "BLOCK: Stage 6E (Refactor) requires the implementation completeness audit. Run '/transmute:cast audit' first."
      exit 1
    fi
    if [[ ! -f "./plancasting/_audits/security/report.md" ]]; then
      echo "BLOCK: Stage 6E (Refactor) requires the security audit. Run '/transmute:cast security' first."
      exit 1
    fi
    if [[ ! -f "./plancasting/_audits/accessibility/report.md" ]]; then
      echo "BLOCK: Stage 6E (Refactor) requires the accessibility audit. Run '/transmute:cast a11y' first."
      exit 1
    fi
    if [[ ! -f "./plancasting/_audits/performance/report.md" ]]; then
      echo "BLOCK: Stage 6E (Refactor) requires the performance audit. Run '/transmute:cast optimize' first."
      exit 1
    fi
    ;;

  seed-data|harden)
    # Stage 6F/6G: Requires 6E
    if [[ ! -f "./plancasting/_audits/refactoring/report.md" ]]; then
      echo "BLOCK: This stage requires the refactoring audit (Stage 6E). Run '/transmute:cast refactor' first."
      exit 1
    fi
    ;;

  docs)
    # Stage 6D: Requires 5B, optimally after 6G (all code changes finalized)
    if [[ ! -f "./plancasting/_audits/implementation-completeness/report.md" ]]; then
      echo "BLOCK: Stage 6D (Documentation) requires the implementation completeness audit. Run '/transmute:cast audit' first."
      exit 1
    fi
    # Warn if running before 6G (code may still change)
    if [[ ! -f "./plancasting/_audits/resilience/report.md" ]]; then
      echo "INFO: Stage 6D is optimal after Stage 6G (resilience hardening). If code changes after 6D, re-run 6D to update docs."
    fi
    ;;

  prelaunch)
    # Stage 6H: Requires 6A-6G complete
    for report in security accessibility performance refactoring resilience; do
      if [[ ! -f "./plancasting/_audits/$report/report.md" ]]; then
        echo "BLOCK: Stage 6H (Pre-Launch) requires all Stage 6 audits. Missing: plancasting/_audits/$report/report.md"
        exit 1
      fi
    done
    ;;

  verify)
    # Stage 6V: Requires 6H + feature scenario generation template
    if [[ ! -f "./plancasting/_launch/readiness-report.md" ]]; then
      echo "BLOCK: Stage 6V (Verification) requires pre-launch report. Run '/transmute:cast prelaunch' first."
      exit 1
    fi
    if [[ ! -f "./plancasting/transmute-framework/feature_scenario_generation.md" ]]; then
      echo "BLOCK: Stage 6V (Verification) requires plancasting/transmute-framework/feature_scenario_generation.md. Copy it from the plugin's templates directory."
      exit 1
    fi
    ;;

  remediate)
    # Stage 6R: Requires 6V report
    if [[ ! -f "./plancasting/_audits/visual-verification/report.md" ]]; then
      echo "BLOCK: Stage 6R (Remediation) requires visual verification report. Run '/transmute:cast verify' first."
      exit 1
    fi
    ;;

  polish)
    # Stage 6P: Requires 6V report (6R may have been skipped)
    if [[ ! -f "./plancasting/_audits/visual-verification/report.md" ]]; then
      echo "BLOCK: Stage 6P (Visual Polish) requires visual verification report. Run '/transmute:cast verify' first."
      exit 1
    fi
    ;;

  redesign)
    # Stage 6P-R: Same prerequisites as 6P — requires 6V report (6R may have been skipped)
    if [[ ! -f "./plancasting/_audits/visual-verification/report.md" ]]; then
      echo "BLOCK: Stage 6P-R (Frontend Design Elevation) requires visual verification report. Run '/transmute:cast verify' first."
      exit 1
    fi
    ;;

  smoke)
    # Stage 7V: Requires 6V report + 6H readiness report + deployment
    if [[ ! -f "./plancasting/_audits/visual-verification/report.md" ]]; then
      echo "BLOCK: Stage 7V (Production Smoke) requires visual verification report (6V). Run '/transmute:cast verify' first."
      exit 1
    fi
    if [[ ! -f "./plancasting/_launch/readiness-report.md" ]]; then
      echo "BLOCK: Stage 7V (Production Smoke) requires pre-launch readiness report (6H). Run '/transmute:cast prelaunch' first."
      exit 1
    fi
    echo "INFO: Stage 7V (Production Smoke) — ensure the app is deployed before running."
    ;;

  user-guide)
    # Stage 7D: Requires 7V PASS
    if [[ ! -f "./plancasting/_audits/production-smoke/report.md" ]]; then
      echo "BLOCK: Stage 7D (User Guide) requires production smoke test. Run '/transmute:cast smoke' first."
      exit 1
    fi
    ;;

  feedback|maintain)
    # Stage 8/9: Post-launch, no hard file prerequisites
    ;;

  *)
    # Non-transmute skill — pass through
    ;;
esac

exit 0
