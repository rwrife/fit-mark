# Fit Mark

Offline bicycle setup journal: cyclists record repeatable fit measurements, compare adjustments and ride notes, and export a bike setup sheet on phone, tablet, and Windows.

## Why / who

Rebuilding a bike position after transport, service, or a component swap is hard when numbers live in photos and scattered notes. Recreational cyclists and home mechanics can record each bike's measured contact-point setup without accounts or subscriptions. This is a measurement journal, not a clinical bike-fit service.

## Intended workflow

1. Add a bike and name measurement reference points and units.
2. Record saddle height from bottom-bracket center, setback, saddle angle, bar reach/drop, stem spacers, and optional notes/photos with explicit measurement methods; mark unknown values as unknown, never zero.
3. Save an adjustment snapshot with date and component context; compare two snapshots with signed deltas and reversible history.
4. Add a short ride note describing comfort or handling in the rider's own words; do not infer injury or prescribe a fit.
5. Export a human-readable setup sheet and portable JSON backup; import validates schema and previews changes before overwrite.

## MVP and limits

- Local bike list, measurement snapshots, delta comparison, ride notes, export/import, and adaptive UI.
- Phone, Android tablet, iPhone/iPad, and Windows desktop; touch and keyboard/mouse.
- No diagnosis, injury prevention claims, fit prescriptions, social feed, cloud sync, Bluetooth sensor requirement, or geometry estimation from photos.
- No permissions for core workflow. Photo attachment, if added, uses user-selected files only. No account, trackers, or network calls. Device-local data and explicit user-owned export; backup files can expose personal notes.

## Status and milestones

Flutter 3.47.7 application skeleton and Windows, Android, iOS CI now exist. App currently shows an empty-state message; bikes, snapshots, backup, platform-authentic Windows UI, and release packaging remain planned. Issues cover those milestones. `AppStore/description.txt` describes planned behavior, not shipped functionality. `AppStore/icon.png` must be generated through spark-media OpenAI Images and inspected before platform wiring; generated Flutter platform icons are temporary scaffold defaults, not production icons.

## Build (after skeleton issue)

Use Flutter 3.47.7 from `toolchain.json`. Run `flutter analyze`, `flutter test`, `flutter build windows --release` on Windows and `flutter build apk --debug` in the Ubuntu container CI lane. iOS simulator build runs on macOS CI. Linux host checks may use Docker; do not infer Windows/iOS build success from Linux tests.

Identifier: `com.infinityball.fitmark` for Android applicationId, iOS bundle ID and Windows/MSIX identity where applicable. iPad and Android tablets enabled. Later store publication may use repository ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8, ASC_TEAM_ID secret names; Windows zip from `.github/workflows/release.yml` on `v*` tag/manual dispatch is MVP release target.

## Manual setup required

App Store Connect bundle ID `com.infinityball.fitmark` could not be registered: `FAILED bundleId lookup rejected: FORBIDDEN_ERROR.PLA_NOT_ACCEPTED`. Account owner must accept current Apple Program License Agreement, then rerun `python3 /home/rwrife/workspaces/tool-lab/asc_create_bundle_id.py fit-mark`. Secret values never belong in repository.
