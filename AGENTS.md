# FreedDigest Agent Rules

This repo contains one Xcode app project at `FreedDigest/FreedDigest.xcodeproj`.
The app source root is `FreedDigest/FreedDigest/`; put new app code there. When
adding, moving, or removing source/resource files, update
`FreedDigest/FreedDigest.xcodeproj` too.

The project already uses `Factory`, `Defaults`, SwiftUI, Core Data, and
swift-log. Reuse those integrations before introducing alternatives. Use the
`FD` prefix for app-specific types, for example `FDRootScreen`, `FDRepository`,
and `FDPersistenceController`.

Use relevant installed skills when needed: SwiftUI Pro for SwiftUI work, Swift
Concurrency for async/task/isolation work, and Core Data Expert for persistence
changes.

## Product Scope

FreedDigest's main feature is fetching a daily digest from the user's Medium
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

Preserve startup: `FreedDigestApp` -> `FDRootScreen` -> splash/onboarding/main.
Navigation uses `FDAppRouter` and `FDAppRoute`; extend those instead of adding
parallel routing. Keep `FDAppRouter` on the Observation framework.
Persistence goes through `FDPersistenceController` and `FDRepository`; do not
access Core Data directly from screens unless explicitly required. Use `Factory`
for long-lived services/repositories that need DI, and register them in
`FreedDigest/FreedDigest/DI/FDApplicationModule.swift`.

Feature UI goes in `FreedDigest/FreedDigest/UI/<Feature>/`. Feature-only
subviews stay with the feature. Shared UI belongs in
`FreedDigest/FreedDigest/UI/Common/` only after reuse across at least two
features is real. Repositories go in `Repository/`. Core Data stack work goes in
`Data/Database/`. Defaults keys go in `Data/UserDefaults/`. Resources go in
`Res/`.

Prefer BLoC-style feature state for new product flows. Use
`FD<Feature>Bloc`, `FD<Feature>State`, and `FD<Feature>Event` for feature state
and user actions instead of adding new pure MVVM view models. Views should send
events to blocs, render bloc state, and keep business logic out of SwiftUI
`body` implementations.

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
screen, bloc, state, event, router, protocol, DTO, repository, and helper types
in one file. Split files when they contain multiple responsibilities, unrelated
types, reusable helpers, or are hard to review.

## SwiftUI And Concurrency

Prefer modern SwiftUI APIs. Use `NavigationStack`. Prefer `Button` over
`onTapGesture` for actions. Keep view state local and minimal. Mark `@State`
private. Keep business logic out of `body`; move it into helpers, blocs, or
models.

Use the Observation framework for new blocs/state models: `@Observable` by
default, not `ObservableObject`. Design state so each view reads only what it
needs; avoid passing broad observable state into static subviews. Split
stateful, binding-heavy, or frequently updating UI into dedicated `View` structs
to reduce invalidation. Keep static/stateless fragments as private computed
properties or helper functions.

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
