# AGENTS.md — مُلتزم (Multazim)

> قواعد العمل لهذا المستودع. تُقرأ تلقائياً بواسطة Antigravity / Cursor / Codex / Claude Code.
> **اقرأ هذا الملف و`docs/MASTER-PROMPT.md` قبل أي تعديل.**

## 1. What this project is

Arabic-first, offline-first Islamic daily companion app (**Flutter**, Android + iOS).
Fully local: **no backend, no accounts, no analytics, no payments, no ads**.
All user data lives in **Hive** on device. Quran text is fetched once then cached.

- UI language: Arabic, **RTL everywhere**. English is a future secondary locale.
- Design: emerald `#0B5D3B` + gold `#C9A227`, ivory `#FAF6ED` / dark `#0D1B16`, Amiri/Tajawal fonts.
- Priority order when requirements conflict:
  **(1) شرعي صحيح ومُوثَّق ← (2) يعمل بلا إنترنت ← (3) جمال الواجهة.**

## 2. Repo state (important)

`lib/` and `pubspec.yaml` are complete. `android/` and `ios/` **do not exist yet** — they are
generated locally (and on CI) with:

```bash
flutter create . --org com.multazim.app --platforms=android,ios
```

Never commit `android/` or `ios/` wholesale changes without need; never commit
`key.properties`, `*.jks`, `build/`, `.dart_tool/`. See `.gitignore`.

Easiest path: run `bash scripts/setup_platforms.sh` (macOS/Linux) or
`powershell -File scripts/setup_platforms.ps1` (Windows). It scaffolds platforms, copies the
release manifest/icons, enables core-library desugaring, patches the iOS `Info.plist`, then
runs `flutter pub get` + `flutter analyze`.

## 3. Commands

```bash
flutter pub get
flutter analyze          # must be clean before you report a task done
flutter test             # add/extend tests with every behaviour change
flutter run              # device/emulator (never add web platform: plugins are mobile-only)
dart format lib/
flutter build apk --release            # personal-use build
flutter build appbundle --release      # Play Store
```

## 4. Hard constraints (do not break)

1. **Never add `vibration` 1.x** — it uses the removed v1 embedding and breaks Android builds.
   Use `HapticFeedback` (already used). If custom patterns are truly needed, `vibration ^3.2.1`
   only (Flutter 3.41+/Dart 3.11+), and only after asking.
2. **`flutter_local_notifications` requires Core Library Desugaring** (`desugar_jdk_libs:2.1.4`).
   Keep `deploy/android/apply_android_gradle.py` working and idempotent.
3. **No new dependency** without a stated reason and explicit user approval. Prefer stdlib/existing packages.
4. **No network calls at build or boot** except the documented Quran/tilawa fetches. Everything else
   must keep working in airplane mode.
5. **No secrets, no telemetry, no third-party SDKs** (Firebase, Ads, Analytics, crash reporting).
6. **Religious content must carry its source** (البخاري/مسلم/أبو داود/حصن المسلم…). Never invent,
   paraphrase, or "improve" a hadith or du'a. If unsure, leave a `TODO(مصدر:)` and tell the user.
7. **Giving section (`features/giving`) never collects money** — external official links only
   (App Store 3.2.2 / Play policy). Keep donations log local + optional hidden amounts.
8. Keep the theme tokens in `lib/core/theme/` — no hard-coded colors in screens.
9. Every user-facing string is Arabic and RTL-safe. Numbers may be Arabic-Indic where already used.

## 5. Architecture map

```
lib/main.dart                 init: Hive, notifications, adhan scheduling, reminders
lib/app.dart                  MaterialApp + RTL + themes
lib/core/theme/               colors + text/theme (fonts via google_fonts)
lib/core/routing/             go_router + 5-tab shell
lib/core/widgets/islamic.dart OrnamentedCard + Islamic ornaments (reuse these)
lib/core/providers/           prayer times (adhan), hijri
lib/core/services/            location, notifications, reminders, backup
lib/features/<feature>/data/          static/structured content + repositories
lib/features/<feature>/presentation/  screens (+ tabs)
```

State: **Riverpod** (`hiveBoxProvider` is the single Hive box, name `multazim`).
Persistence keys: add a small typed helper per feature instead of scattering raw strings.

## 6. Definition of done (report this in your final message)

- [ ] `flutter analyze` clean, `flutter test` passing
- [ ] Works offline; dark + light theme checked; RTL checked; small screens (360×640) checked
- [ ] No new dependency, or approval noted
- [ ] Files changed listed with one-line rationale each
- [ ] Manual test steps given (what the user should tap)
- [ ] Docs updated when behaviour/flows changed (`README.md`, `docs/`)

## 7. How to work with the user

- One feature per conversation/task. Keep diffs reviewable; no drive-by refactors.
- Ask before changing schema of Hive data or removing existing features.
- Prefer **Planning first**: propose a short plan, then implement.
- Never run destructive git commands; never force-push; never commit signing keys.
- Commit messages: `feat(quran): …` / `fix(notifications): …` / `docs: …` (body in Arabic allowed).

## 8. Roadmap (open items only — see README for the full list)

1. Missing assets: `assets/sounds/adhan_*.mp3`, `assets/fonts/AmiriQuran-Regular.ttf` (+ copy sounds to `android/app/src/main/res/raw/`).
2. Mushaf as **604 pages** (currently surah-based) + juz/hizb index.
3. Memorisation plan + review loop (حفظ ومراجعة).
4. Full Hisn al-Muslim dataset (`assets/data/adhkar_full.json`) with sources.
5. Widget tests + golden tests; a11y audit; performance pass.
6. English locale toggle.
7. Release: signing, store builds, Codemagic verification.
