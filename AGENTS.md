# AGENTS.md: Developer & Agent Operational Directives

## 1. Project Overview & Role
**Tsuzuri v2** is a lightweight, offline-first, cross-platform Markdown editor and reader implemented in **Flutter and Dart**.
It prioritizes dependable rendering correctness, true AMOLED dark mode readability, offline operation, robust file handling, and first-class LaTeX and Mermaid diagram support.

When working on this repository, act as a senior Flutter engineer, software architect, rendering-engine specialist, and UI/UX designer.

## 2. Core Architectural Principles
1. **Flutter & Dart First**:
   - The primary application shell, navigation, file management, UI controls, menus, dialogs, drawers, and editor are implemented using idiomatic Flutter widgets.
   - Do not wrap an Electron, Tauri, or generic web application as the app shell.
   - Use native filesystem APIs via Dart standard library (`dart:io`) and Flutter plugins where appropriate.
2. **Mutually Exclusive Reader & Editor Views**:
   - The application has two distinct document views: **Reader** (formatted, typeset read-only view) and **Editor** (raw Markdown source editing).
   - These modes are **mutually exclusive**. NEVER implement a split-pane editor and live preview.
3. **Dedicated Rendering Component**:
   - Markdown parsing, mathematical typesetting, Mermaid rendering, syntax highlighting, and local asset resolution must be cleanly decoupled.
   - For complex LaTeX (MathJax with AMS, physics, mhchem, cancel, etc.) and Mermaid SVG rendering, use a dedicated, offline-bundled rendering pipeline.
   - All rendering resources (scripts, stylesheets, fonts) must be bundled locally inside application assets. Zero CDN dependencies; zero network access required at runtime.
4. **AMOLED Pure Black & Restrained Typography**:
   - Three theme modes: **System** (default), **Light** (`#fcfcfc` canvas), and **AMOLED Dark** (`#000000` canvas).
   - High contrast, legible typography inspired by Tsuzuri v1 design tokens.
5. **No Data Loss & Safe Document I/O**:
   - External file changes, unsaved edits, and mode switches must be guarded with state checks and user prompts.
   - Atomic / safe file saving to prevent corruption.

## 3. Persistent Progress & Resume Protocol
This repository maintains 5 authoritative persistent coordination files in the root:
- `AGENTS.md`: Permanent instructions, architecture rules, coding standards, and safety constraints.
- `PROJECT_STATUS.md`: Current phase, task completion percentage, active task, test records, blockers, and next actions.
- `IMPLEMENTATION_PLAN.md`: Phased roadmap with stable task IDs (`PHASE0-001`, `POC-001`, `CORE-001`, etc.), acceptance criteria, and verification logs.
- `DECISIONS.md`: Architectural Decision Records (ADRs) explaining technical choices, trade-offs, and deviations.
- `KNOWN_ISSUES.md`: Confirmed defects, limitations, platform constraints, and unresolved risks.

### Resuming Work (Mandatory Procedure)
Whenever an agent begins a session or resumes after interruption:
1. Read `AGENTS.md`.
2. Read `PROJECT_STATUS.md`.
3. Read `IMPLEMENTATION_PLAN.md`.
4. Read `DECISIONS.md` and `KNOWN_ISSUES.md`.
5. Run `git status` and inspect actual code to reconcile persistent status with repository reality.
6. Resume from the earliest incomplete or unverified task.
7. Update `PROJECT_STATUS.md` and `IMPLEMENTATION_PLAN.md` after each meaningful task.

## 4. Coding & Verification Standards
- Maintain documentation integrity: do not delete or overwrite valid instructions.
- Work in small, recoverable increments. Keep code buildable and testable at each step.
- Verify acceptance criteria using actual CLI commands (`flutter analyze`, `flutter test`, `flutter build ...`). Never mark a task `VERIFIED` without executing concrete checks.
- Do not commit or push unless explicitly instructed by the user.
- Ensure any other agent can seamlessly continue work from the persistent files alone.

