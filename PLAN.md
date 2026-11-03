# Fit Mark plan

## Scope and architecture

Flutter stable single Dart codebase with `windows/`, `android/`, `ios/` enabled from first skeleton. Store bikes, explicitly defined measurement points, snapshots and ride notes locally. Pure Dart domain rules calculate signed deltas only when comparable units/reference points exist; mismatched measurements show unknown. Import/export versioned JSON with validation and preview before replacement. PDF/printable setup sheet can follow from local data. Identifier `com.infinityball.fitmark` for Android applicationId, iOS bundle ID and Windows/MSIX identity where applicable; native iPad and Android tablet support enabled.

## Platform-authentic UX: strategy A

Use small adaptive-widget layer: `AdaptiveScaffold`, `AdaptiveButton`, `AdaptiveDialog`; iOS/iPadOS Cupertino navigation, swipe-back and sheets; Android Material 3, Android back and native pickers; Windows Fluent navigation/command bar, keyboard shortcuts, context menus and resizable panes. Never Material on iOS, Cupertino on Android, or phone UI on Windows. Do not duplicate domain logic in widgets. Touch targets, semantic labels, font scaling, high contrast, keyboard focus/order and screen-reader labels required. Record measurement method beside value so physically different references are not compared. No extra platform dependency before native widgets or existing package proves insufficient.

## Milestones / dependencies

1. Flutter skeleton with three platform folders and Windows/Android CI, baseline widget tests.
2. Local domain: bike, measurement definition/unit, immutable snapshots, comparison, tests.
3. Bike editing and snapshot workflow, date/undo handling.
4. Ride notes and comparisons.
5. Platform-adaptive navigation and responsive phone/tablet/desktop surfaces, platform golden/widget tests.
6. Versioned JSON backup/import and printable setup sheet; privacy controls.
7. Generate and wire real icon, audit listing and accessibility.
8. Windows release workflow and downloadable zip.

## Testing

Pure Dart unit tests for null vs zero, unit conversion, mismatched reference points, signed deltas, import validation and round trips. Widget/golden tests render key screens under `TargetPlatform.iOS`, `TargetPlatform.android`, `TargetPlatform.windows` at phone, tablet and desktop window sizes; test touch and keyboard focus/back. `windows-latest` runs `flutter test` and `flutter build windows --release`; Linux/Docker runs tests and `flutter build apk --debug`; keep iOS compiling via macOS CI when available. Do not claim any build yet: this scaffold has no app skeleton.

## Distribution

`.github/workflows/release.yml`: `v*` tag or manual dispatch, `windows-latest` builds release Flutter Windows binary, zips and attaches to GitHub release. Android/iOS phone/tablet targets remain first-class, but Play and TestFlight publication are later opt-in milestones. ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8, ASC_TEAM_ID secret names exist for later store workflows; Apple registration blocked by `FORBIDDEN_ERROR.PLA_NOT_ACCEPTED` until account owner accepts PLA. `AppStore/description.txt` must match shipped features. Generate real `AppStore/icon.png` with spark-media OpenAI Images, inspect and wire Windows `.ico`, Android launcher and iOS catalog.

## Risks / non-goals

Measurement ambiguity: label units and reference points, never prescribe adjustments or conflate distinct methods. Non-medical personal journal: no diagnosis, treatment, injury prevention, emergencies. No cloud accounts, trackers, social feed, automatic photo fit estimation, live sensor pairing, or platform-inappropriate UI. User-owned local backup is essential because uninstall may delete data.
