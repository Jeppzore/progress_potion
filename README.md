# ProgressPotion

ProgressPotion is a Flutter habit tracking app. This Phase 1 setup establishes the app shell, seeded habit data, Android-ready project structure, and the agent briefs that will guide later feature work.

## Current foundation

- Single-root Flutter project at the repository root
- Material 3 app shell with Home and Tasks placeholder screens
- Domain scaffolding for habits in `lib/models` and `lib/services`
- In-memory seeded data to exercise the UI before persistence lands
- Root-level agent briefs for orchestration, implementation, UX, review, and QA

## Project structure

```text
lib/
  app/
  core/
  models/
  screens/
  services/
  widgets/
test/
  services/
```

## Getting started

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Android focus

Phase 1 is validated primarily for Android. The application ID is `com.progresspotion.app`, and the app launches with a lightweight shell that is ready for the next feature phase.
