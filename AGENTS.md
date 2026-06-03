# FreedDigest Agent Rules

This repo contains one Xcode app project at `FreedDigest/FreedDigest.xcodeproj`.
The app source root is `FreedDigest/FreedDigest/`; put new app code there. When adding,
moving, or removing source/resource files, update `FreedDigest/FreedDigest.xcodeproj` too.

The project already uses `Factory`, `Defaults`, SwiftUI, and Core
Data. Reuse those integrations before introducing alternatives. Use the `FD`
prefix for app-specific types, for example `FDRootScreen`, `FDRepository`,
and `FDPersistenceController`.

Use relevant installed skills when needed: SwiftUI Pro for SwiftUI work, Swift
Concurrency for async/task/isolation work, and Core Data Expert for persistence
changes.

## Architecture And Placement

Preserve startup: `FreedDigestApp` -> `FDRootScreen` -> splash/onboarding/main.
Navigation uses `FDAppRouter` and `FDAppRoute`; extend those instead of adding
parallel routing. Persistence goes through `FDPersistenceController` and
`FDRepository`; do not access Core Data directly from screens unless explicitly
required. Use `Factory` for long-lived services/repositories that need DI, and
register them in `FreedDigest/FreedDigest/DI/FDApplicationModule.swift`.

Feature UI goes in `FreedDigest/FreedDigest/UI/<Feature>/`. Feature-only subviews stay with
the feature. Shared UI belongs in `FreedDigest/FreedDigest/UI/Common/` only after reuse
across at least two features is real. Repositories go in `Repository/`. Core
Data stack work goes in `Data/Database/`. Defaults keys go in
`Data/UserDefaults/`. Resources go in `Res/`.

Prefer small, reviewable changes over broad refactors. Preserve existing
structure and naming unless there is a clear reason to change it. Do not modify
unrelated files just because they can be improved. Keep implementation
practical: fix the real issue first, then clean up only directly adjacent code.
Explain changes clearly in responses and state why the approach fits this
project.

## Code Quality

Do not use `print(...)` in production code. Avoid force unwraps and `try!`.
Prefer explicit, value-driven code over clever
abstractions. Remove dead code, debug leftovers, and temporary scaffolding
before finishing.

One file should contain one primary type and match its type name. Do not mix
screen, view model, router, protocol, DTO, repository, and helper types in one
file. Split files when they contain multiple responsibilities, unrelated types,
reusable helpers, or are hard to review.

## SwiftUI And Concurrency

Prefer modern SwiftUI APIs. Use `NavigationStack`. Prefer `Button` over
`onTapGesture` for actions. Keep view state local and minimal. Mark `@State` and
`@StateObject` private. Keep business logic out of `body`; move it into helpers
or models.

Use the Observation framework for new view models/state models: `@Observable`
by default, not `ObservableObject`. Design view model state so each view reads
only what it needs; avoid passing broad observable state into static subviews.
Split stateful, binding-heavy, or frequently updating UI into dedicated `View`
structs to reduce invalidation. Keep static/stateless fragments as private
computed properties or helper functions.

Prefer structured concurrency with async/await and child tasks. Use `@MainActor`
for UI-bound state and UI-triggered side effects. Do not use `Task.detached`
without a concrete isolation reason.

## Resources

Reuse existing assets and strings first. When implementing from Figma, import
missing resources through Figma MCP.

Images: `Res/Assets.xcassets/Image/`, named `img_<name>`, with 2x/3x.
Colors: `Res/Assets.xcassets/Color/`, named `c_<HEX>`.
Strings: `Res/Localizable.xcstrings`; avoid hard-coded user-facing text.

Use generated symbols such as `Image(.imgBack)`, `Color.cFFFFFF`, and
`Text(.helloWorld)`.

## Verification

For code changes, prefer:
`xcodebuild -project FreedDigest/FreedDigest.xcodeproj -scheme FreedDigest -destination 'generic/platform=iOS Simulator' build`
