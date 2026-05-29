# Mobile POS Flutter - Project Rules

This document defines the foundational mandates and development standards for the Mobile POS Flutter project. All AI agents and developers must strictly adhere to these rules.

## 1. Architectural Mandates
- **Feature-First Architecture:** All new functionality must be organized into features under `lib/features/<feature_name>/`.
- **Feature Structure:** Each feature directory MUST contain the following sub-directories:
  - `data/`: Data sources, repositories, and models (using Freezed).
  - `presentation/`: UI components, screens, and widgets.
  - `providers/`: Riverpod providers and Notifiers.
- **Core Logic:** Global utilities, shared themes, routing, and hardware interfaces live in `lib/core/`.

## 2. State Management & Data
- **Riverpod:** Use `flutter_riverpod`. Prefer `Notifier` or `AsyncNotifier` (using the `@riverpod` generator where applicable, or standard `NotifierProvider`).
- **Immutability:** All data models and states MUST use `freezed` and `json_serializable`.
- **Updates:** Always use `.copyWith()` for state updates to maintain immutability.

## 3. Navigation
- **GoRouter:** All routes must be declared in `lib/core/router/app_router.dart`.
- **Declarative:** Use declarative navigation patterns provided by `go_router`.

## 4. Coding Standards
- **File Naming:** `snake_case.dart` (e.g., `product_repository.dart`).
- **Class Naming:** `PascalCase` (e.g., `ProductNotifier`).
- **Method/Variable Naming:** `camelCase`.
- **Strong Typing:** Always specify types for variables, parameters, and return values. Avoid `dynamic`.

## 5. Testing Requirements
- **Location:** Tests must be placed in the `test/` directory, mirroring the `lib/` structure (e.g., `test/features/<feature_name>/`).
- **Unit Tests:** Every `Notifier` or business logic component MUST have a corresponding unit test.
- **Execution:** Ensure `flutter test` passes before finalizing changes.

## 6. Generator Workflow
- After modifying files with `@freezed`, `@JsonSerializable`, or `@riverpod`, always run:
  `flutter pub run build_runner build --delete-conflicting-outputs`
