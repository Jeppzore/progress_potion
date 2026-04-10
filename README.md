# ProgressPotion

ProgressPotion is a Flutter task-tracking MVP with a lightweight game loop. The app supports adding categorized tasks, completing tasks, and filling a potion meter that awards XP with local progress persistence.

## Current MVP

- Single-root Flutter project at the repository root
- Material 3 home flow with a potion progress card and add-task screen
- Required task categories for Fitness, Study, Work, Hobby, and Home
- Task domain scaffolding in `lib/models`, `lib/services`, and `lib/controllers`
- First-run seeded data plus locally persisted task creation, completion, potion rewards, total XP, and category variety bonus progress
- Root-level agent briefs for orchestration, implementation, UX, review, and QA

## Project structure

```text
lib/
  app/
  controllers/
  core/
  models/
  screens/
  services/
  widgets/
test/
  controllers/
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

The MVP is validated primarily for Android. The application ID is `com.progresspotion.app`, and the app launches into the main task loop with session-only progress.
