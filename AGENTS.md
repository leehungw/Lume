# Lume Agent Rules

This repo contains one Xcode app project at `Lume/Lume.xcodeproj`.
The app source root is `Lume/Lume/`; put new app code there. When
adding, moving, or removing source/resource files, update
`Lume/Lume.xcodeproj` too.

The project already uses `Factory`, `Defaults`, SwiftUI, Core Data, and
swift-log. Reuse those integrations before introducing alternatives. Use the
`LM` prefix for app-specific types, for example `LMRootScreen`, `LMRepository`,
and `LMPersistenceController`.

Use relevant installed skills when needed: SwiftUI Pro for SwiftUI work, Swift
Concurrency for async/task/isolation work, and Core Data Expert for persistence
changes.

## Product Scope

Lume's main feature is fetching a daily digest from the user's Medium
account, then using Freedium to retrieve the full content for each post when
needed. Treat Medium account access, digest import, Freedium content retrieval,
and article refresh behavior as core product flows.

Secondary features support reading workflows around those posts: storing posts,
adding notes, organizing saved material into knowledge-focused collections, and
summarizing posts into smaller pieces so users can quickly catch up on the
newest trends in their topics.

When adding product behavior, preserve this hierarchy: digest fetching and full
post retrieval are primary; storage, notes, knowledge organization, and summaries
should build on the fetched posts rather than becoming unrelated content systems.

## Architecture And Placement

Preserve startup: `LumeApp` -> `LMRootScreen` -> splash/onboarding/main.
Navigation uses `LMAppRouter` and `LMAppRoute`; extend those instead of adding
parallel routing. Keep `LMAppRouter` on the Observation framework.
Persistence goes through `LMPersistenceController` and `LMRepository`; do not
access Core Data directly from screens unless explicitly required. Use `Factory`
for long-lived services/repositories that need DI, and register them in
`Lume/Lume/DI/LMApplicationModule.swift`.

Feature UI goes in `Lume/Lume/UI/<Feature>/`. Feature-only
subviews stay with the feature. Shared UI belongs in
`Lume/Lume/UI/Common/` only after reuse across at least two
features is real. Repositories go in `Repository/`. Core Data stack work goes in
`Data/Database/`. Defaults keys go in `Data/UserDefaults/`. Resources go in
`Res/`.

Use MVVM with the Observation framework for feature state and user actions. For
each stateful feature, keep the view and view model in separate files, using
names such as `LM<Feature>Screen` and `LM<Feature>ViewModel`. Put feature view
models in `Lume/Lume/UI/<Feature>/ViewModel/` unless the feature
already has a more specific local structure. New view models should use
`@Observable` by default, not `ObservableObject`.

Keep responsibilities clear without over-engineering. Views should own only
view-local state and presentation details, render view-model state, and forward
user actions to the view model. View models should own screen state,
coordination, validation, async work, and calls into repositories or services.
Do not put business logic in SwiftUI `body` implementations. Add extra state
types, coordinators, or abstractions only when they remove real complexity.

Prefer small, reviewable changes over broad refactors. Preserve existing
structure and naming unless there is a clear reason to change it. Do not modify
unrelated files just because they can be improved. Keep implementation
practical: fix the real issue first, then clean up only directly adjacent code.
Explain changes clearly in responses and state why the approach fits this
project.

## Problem Solving Approach

Prefer the simplest solution that satisfies the current requirement. Start by
looking for an existing owner, existing data flow, existing layout structure, or
existing helper that can solve the problem with a small local change.

When solving implementation problems, use this order: reuse existing structure,
make a small local change, add narrowly scoped state or helpers only if needed,
and add broader abstractions or model changes only as a last resort.

Optimize for fewer moving parts, fewer touched files, and clearer ownership over
a more generic or theoretically complete design. Do not solve future or
hypothetical requirements unless explicitly asked. If choosing a more complex
solution, briefly explain why the simpler approach is insufficient.

## Code Quality

Use `Loggable` with `logInfo`, `logDebug`, `logWarning`, and `logError`; do not
use `print(...)` in production code. Avoid force unwraps and `try!`. Prefer
explicit, value-driven code over clever abstractions. Remove dead code, debug
leftovers, and temporary scaffolding before finishing.

One file should contain one primary type and match its type name. Do not mix
screen, view model, router, protocol, DTO, repository, and helper types in one
file. Split files when they contain multiple responsibilities, unrelated types,
reusable helpers, or are hard to review.

## SwiftUI And Concurrency

Prefer modern SwiftUI APIs. Use `NavigationStack`. Prefer `Button` over
`onTapGesture` for actions. Keep view state local and minimal. Mark `@State`
private. Keep business logic out of `body`; move it into helpers, view models,
or models.

Use the Observation framework for new view models and shared UI state:
`@Observable` by default, not `ObservableObject`. Design state so each view
reads only what it needs; avoid passing broad observable state into static
subviews. Split stateful, binding-heavy, or frequently updating UI into
dedicated `View` structs to reduce invalidation. Keep static/stateless fragments
as private computed properties or helper functions.

Prefer structured concurrency with async/await and child tasks. Use `@MainActor`
for UI-bound state and UI-triggered side effects. Do not use `Task.detached`
without a concrete isolation reason.

## Resources

Reuse existing assets and strings first. When implementing from Figma, import
missing resources through Figma MCP.

Images: `Res/Assets.xcassets/Image/`, named `img_<name>`, with 2x/3x. The
resource filenames in Finder must match the Xcode asset name: for asset
`img_back`, use `img_back@2x.png` and `img_back@3x.png`.
Colors: `Res/Assets.xcassets/Color/`, named `c_<HEX>`.
Strings: `Res/Localizable.xcstrings`; avoid hard-coded user-facing text. For
short strings, make the key equal the value. For long strings, use concise
semantic keys.

Use generated symbols such as `Image(.imgBack)`, `Color.cFFFFFF`, and
`Text(.helloWorld)`.

## Verification

Do not run `xcodebuild` by default. For code changes, make the implementation
and report that the build was not run per repo instructions. Only build when the
user explicitly requests verification.

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **Lume** (582 symbols, 2177 relationships, 36 execution flows). Use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

> Index stale? Run `node .gitnexus/run.cjs analyze` from the project root — it auto-selects an available runner. No `.gitnexus/run.cjs` yet? `npx gitnexus analyze` (npm 11 crash → `npm i -g gitnexus`; #1939).

## Always Do

- **MUST run impact analysis before editing any symbol.** Before modifying a function, class, or method, run `impact({target: "symbolName", direction: "upstream"})` and report the blast radius (direct callers, affected processes, risk level) to the user.
- **MUST run `detect_changes()` before committing** to verify your changes only affect expected symbols and execution flows. For regression review, compare against the default branch: `detect_changes({scope: "compare", base_ref: "master"})`.
- **MUST warn the user** if impact analysis returns HIGH or CRITICAL risk before proceeding with edits.
- When exploring unfamiliar code, use `query({query: "concept"})` to find execution flows instead of grepping. It returns process-grouped results ranked by relevance.
- When you need full context on a specific symbol — callers, callees, which execution flows it participates in — use `context({name: "symbolName"})`.

## Never Do

- NEVER edit a function, class, or method without first running `impact` on it.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis.
- NEVER rename symbols with find-and-replace — use `rename` which understands the call graph.
- NEVER commit changes without running `detect_changes()` to check affected scope.

## Resources

| Resource | Use for |
|----------|---------|
| `gitnexus://repo/Lume/context` | Codebase overview, check index freshness |
| `gitnexus://repo/Lume/clusters` | All functional areas |
| `gitnexus://repo/Lume/processes` | All execution flows |
| `gitnexus://repo/Lume/process/{name}` | Step-by-step execution trace |

## CLI

| Task | Read this skill file |
|------|---------------------|
| Understand architecture / "How does X work?" | `.claude/skills/gitnexus/gitnexus-exploring/SKILL.md` |
| Blast radius / "What breaks if I change X?" | `.claude/skills/gitnexus/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?" | `.claude/skills/gitnexus/gitnexus-debugging/SKILL.md` |
| Rename / extract / split / refactor | `.claude/skills/gitnexus/gitnexus-refactoring/SKILL.md` |
| Tools, resources, schema reference | `.claude/skills/gitnexus/gitnexus-guide/SKILL.md` |
| Index, status, clean, wiki CLI commands | `.claude/skills/gitnexus/gitnexus-cli/SKILL.md` |

<!-- gitnexus:end -->
