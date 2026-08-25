# Contributing to fluent_2

Thank you for your interest in contributing to **fluent_2**! This project provides a faithful Flutter implementation of Microsoft's Fluent 2 design system as a Dart pub workspace.

Please review these guidelines to ensure a smooth contribution process.

---

## 🛑 Core Architectural Rule: No Material / Cupertino Dependencies

> **IMPORTANT**: `fluent_2` is designed to **replace Material and Cupertino**, not layer on top of them.

- **Never import `package:flutter/material.dart` or `package:flutter/cupertino.dart`**.
- All components, widgets, and utilities must be built purely on top of **`package:flutter/widgets.dart`** and **`package:flutter/rendering.dart`**.
- Compliance is strictly enforced in CI via `melos run no-material`.

---

## 📁 Repository Layout

This project is managed as a monorepo using **Dart Pub Workspace** and **Melos 7+**:

```text
packages/
├── fluent_2_core/           # Shared foundation: tokens, color ramps, typography, theming & app shell
├── fluent_2/                # Fluent 2 components (buttons, inputs, surfaces, etc.)
├── fluent_2_fonts/          # Platform-agnostic font facade
└── fluent_2_fonts_*/        # Platform-specific font packages (web, windows, macos, ios, android)
```

Packages are organized by **surface** (e.g., `fluent_2`) rather than component category. Each UI surface package depends on and re-exports `fluent_2_core`.

---

## 🛠️ Local Setup & Workflow

### Prerequisites

- **Flutter SDK**: `^3.12.2` (or latest stable compatible release)
- **Dart SDK**: `^3.12.2`
- **Melos**: Install globally or use through `dart run melos` / `flutter pub run melos`:
  ```bash
  dart pub global activate melos 7.0.0
  ```

### Getting Started

1. **Clone the repository**:
   ```bash
   git clone https://github.com/B1Digital/fluent_ui_2_flutter.git
   cd fluent_2
   ```

2. **Install dependencies across the workspace**:
   ```bash
   flutter pub get
   ```

3. **Run the example application**:
   ```bash
   cd packages/fluent_2/example
   flutter run -d chrome
   ```

---

## 🧪 Quality Gates & CI Commands

Before submitting a Pull Request, run the full suite of verification checks via Melos:

| Command | Description |
| :--- | :--- |
| `melos run analyze` | Runs `dart analyze --fatal-infos` across all packages. |
| `melos run format` | Verifies code formatting (`dart format --set-exit-if-changed .`). |
| `melos run no-material` | Asserts no package imports Material or Cupertino libraries. |
| `melos run test` | Executes unit tests across all packages. |
| `melos run ci` | **Executes all checks above sequentially (Analyze + Format + No-Material + Test).** |

Make sure `melos run ci` succeeds cleanly before opening or updating a Pull Request.

---

## 🎨 Design System & Code Guidelines

1. **Design Tokens over Hardcoded Values**:
   - Always derive colors, spacing, radii, elevations, and animations from the active theme:
     ```dart
     final theme = FluentTheme.of(context);
     theme.colors.brandBackground;
     theme.typography.subtitle1;
     theme.shadow(FluentElevation.shadow8);
     FluentSpacing.l;
     FluentRadius.medium;
     FluentDuration.normal;
     FluentCurve.decelerateMid;
     ```
2. **Component Structure**:
   - Keep component code in `fluent_2`.
   - Reusable logic and token tables belong in `fluent_2_core`.
3. **Tests**:
   - Add unit tests under the `test/` folder of the modified package.
   - For golden / visual regression tests, ensure they are executed cleanly.
4. **Documentation**:
   - Provide clean Dartdoc comments (`///`) for all public classes, methods, and token getters.

---

## 📬 Submitting a Pull Request

1. **Fork & Branch**:
   - Create a feature or bugfix branch off `main`:
     ```bash
     git checkout -b feature/my-new-component
     ```
2. **Commit Conventions**:
   - Write clear, concise commit messages describing *what* and *why*.
3. **Verify Locally**:
   - Run `melos run ci` and verify 0 errors, warnings, or lint issues.
4. **Open Pull Request**:
   - Target the `main` branch.
   - Include a concise summary of the changes and link any relevant issues.
   - Provide screenshots or recordings if introducing or modifying UI components.

---

## 📜 Code of Conduct

Please be respectful, collaborative, and constructive when opening issues, submitting pull requests, or reviewing code.

---

Thank you for helping build a top-tier Fluent 2 design system for Flutter! 🚀
