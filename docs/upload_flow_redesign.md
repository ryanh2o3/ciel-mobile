# Upload Flow Redesign

A staged plan for modernizing the story + post creation screens in
`ciel_mobile`. Each phase is intended to ship as a standalone, reviewable
slice — the app stays usable between phases.

The current entry screens that this plan replaces:

- `lib/features/stories/presentation/create_story_screen.dart` — "New story"
- `lib/features/post/presentation/create_post_screen.dart` — "New post"

Shared layer touched by every phase:

- Theme: `lib/app/theme/app_theme.dart` (Material 3, seed `#5B8DEF`)
- Tokens: `lib/ui/tokens.dart` (`CielSpacing`, `CielRadii`)
- Design system widgets: `lib/ui/`
- DI: `lib/app/providers/dependency_providers.dart`
- Pipeline: `lib/domain/usecases/media_use_case.dart`
  (intent → upload → complete → poll)

---

## Guiding principles

1. **Photo-first.** Once a photo is selected it is the largest element.
2. **Thumb-zone primary actions.** The "Share" button lives at the bottom,
   not in the AppBar.
3. **Progressive disclosure.** Advanced controls (location, tags, alt text,
   comments-off) hide behind a single "Advanced" row.
4. **One source of truth per flow.** State for an in-progress upload lives
   in a Riverpod `Notifier`, not `setState`. This unlocks drafts and a
   global upload indicator later.
5. **Stories ≠ Posts.** Share the picker and upload plumbing; diverge in
   the compose step. Stories are full-bleed and expressive; posts are
   curated and structured.

---

## Phase 1 — Compose redesign (no flow change)

**Goal:** kill the empty-screen feel and the dropdown. Same single-screen
flow, much better layout. Lowest risk, biggest visible win.

**New layout (both screens):**

```
┌─────────────────────────────────────┐
│ ✕   New story / New post            │  AppBar: cancel only
├─────────────────────────────────────┤
│  ┌────┐  Write a caption…           │  Thumbnail (72px) + auto-grow
│  │IMG │                             │  caption + char counter
│  └────┘                             │
├─────────────────────────────────────┤
│  👥  Audience          Public  ›    │  CielComposeRow
│  📍  Add location              ›    │  (story+post)
│  🏷  Tag people                 ›    │  (post only)
│  ⚙  Advanced                   ›    │
├─────────────────────────────────────┤
│        [   Share   ]                │  CielPrimaryButton, pinned
└─────────────────────────────────────┘
```

**Deliverables (Phase 1):**

- `lib/ui/ciel_compose_row.dart` — icon + label + trailing value + chevron.
- `lib/ui/ciel_audience_picker_sheet.dart` — `showModalBottomSheet` that
  takes the current `StoryVisibility` and returns the new selection. Each
  row: icon, name, one-line description, checkmark when selected.
- `lib/ui/ciel_thumbnail.dart` — small rounded thumbnail with empty-state
  ("Choose photo") that taps through to the picker.
- Rewrite `create_story_screen.dart` and `create_post_screen.dart` to use
  the new layout + existing `CielPrimaryButton` for the bottom CTA.
- Tests: widget tests covering empty/photo-selected/error states for both
  screens.

**Out of scope for Phase 1:** changes to the upload pipeline, drafts, edit
step, camera capture.

---

## Phase 2 — Upload feedback

**Goal:** make uploads legible. The media pipeline already has four
distinct phases (intent → upload → complete → poll status); surface them.

**Deliverables:**

- `lib/features/stories/presentation/create_story_notifier.dart` and
  `lib/features/post/presentation/create_post_notifier.dart`. Each exposes:

  ```dart
  sealed class CreateUploadState {
    const CreateUploadState();
  }
  class Idle extends CreateUploadState {}
  class Preparing extends CreateUploadState {}
  class Uploading extends CreateUploadState {
    final int index, total; final double progress;
  }
  class Processing extends CreateUploadState {}
  class Done extends CreateUploadState {}
  class Failed extends CreateUploadState { final String message; ... }
  ```

- `lib/ui/ciel_upload_overlay.dart` — fullscreen modal overlay showing
  phase label + determinate or indeterminate progress; sized to the
  thumbnail strip for posts.
- Error mapping helper that converts thrown exceptions into a short,
  user-friendly message (network / server / processing / unknown) plus a
  Retry callback.
- Replace the bare `LinearProgressIndicator` and red error `Text` in the
  Phase 1 screens.

**Tradeoff:** the upload pipeline currently returns no per-chunk progress
events from Dio's media upload. Phase 2 surfaces phases first; per-byte
progress requires plumbing a `onSendProgress` callback through
`MediaRepositoryImpl` → `MediaUseCase` → notifier — do that here too.

---

## Phase 3 — Edit step

**Goal:** let users crop/rotate before posting. Today the raw picked file
is uploaded as-is.

**Deliverables:**

- Add `image_cropper` to `pubspec.yaml` (and the iOS/Android native setup
  it requires).
- New route: `/stories/create/edit` and `/create/edit` rendered as a step
  in the flow. Use a `PageView` inside the create route instead of new
  GoRouter destinations — back gestures stay natural.
- Edit toolbar: crop (1:1 post default, 9:16 story default, plus 4:5
  option for posts), rotate 90°, replace photo (re-opens picker).
- Posts: draggable thumbnail strip with delete affordance using
  `ReorderableListView.builder` horizontally (or a simple custom widget if
  the built-in is too heavy in the horizontal layout).

**Tradeoff:** `image_cropper` is a native dependency with platform setup
in `Info.plist` and `AndroidManifest.xml`. If we want zero new native
deps, the alternative is a pure-Dart cropping widget (e.g. `crop` package
or a hand-rolled `InteractiveViewer` + mask) — slower to build and lower
fidelity.

---

## Phase 4 — Story overlay editor

**Goal:** make story composition feel like Stories elsewhere
(IG/Snap/BeReal): full-bleed, expressive, text lives on the image.

**Deliverables:**

- New widget tree for stories' compose step:

  ```
  ┌─────────────────────────────────────┐
  │ ✕                            Aa     │  text tool
  │                                     │
  │         [ full-bleed photo ]        │
  │                                     │
  │         tap to add text             │
  │                                     │
  ├─────────────────────────────────────┤
  │  Public ▾      [ Share story → ]    │
  └─────────────────────────────────────┘
  ```

- Caption rendered as a draggable text overlay (v1 = bottom-anchored,
  single line, no drag). Auto-contrast pill background behind the text
  using the photo's average luminance at that band (lightweight: sample a
  few pixels via `dart:ui` `Image.toByteData`).
- Audience as a compact chip in the bottom bar, opening the same
  `CielAudiencePickerSheet` from Phase 1.
- Persist overlay text into `caption` on submit (no server-side rendering;
  the iOS/Android viewers can render the same overlay client-side later).

**Tradeoff:** if/when caption is rendered as overlay client-side in the
viewer too, we'll need a small "overlay metadata" field on the story
entity (font/position). For now, keep caption as plain text and just
*display* it as an overlay in the composer; the viewer keeps its existing
caption rendering.

---

## Phase 5 — Capture step + drafts

**Goal:** let users capture from the camera (without a custom viewfinder)
and never lose work to an accidental back tap.

**Deliverables (as shipped):**

- Source-chooser bottom sheet — `showCielPhotoSourceSheet` returns
  `CielPhotoSource.{camera, library}`. Both routes go through the
  existing `CielImageEditor.pickAndCrop`. Uses `image_picker`'s
  `ImageSource.camera` for the system camera — no new package.
- `NSCameraUsageDescription` + `NSPhotoLibraryUsageDescription` added to
  `ios/Runner/Info.plist`.
- Draft model: `CreateStoryDraft` (`imagePath?, caption, visibility`) and
  `CreatePostDraft` (`imagePaths[], caption`). Stored as JSON in
  `SharedPreferences`. One slot per type.
- `CreateDraftStore` (`lib/features/uploads/draft/`) handles
  save/load/clear. On load it scrubs `imagePath`s whose files no longer
  exist (the OS may have purged the temp dir between launches) so the
  caption survives even when the photo doesn't.
- Both compose screens: post-frame `_offerDraftRestore` shows a snackbar
  on entry with a single "Discard" action (drafts are restored
  automatically; the snackbar tells the user and offers undo).
- `_scheduleDraftSave` fires on every meaningful state change (image
  picked/cropped/replaced/reordered/removed, caption typed, visibility
  changed). SharedPreferences writes are buffered by the platform, so no
  debounce needed.
- Drafts are cleared on successful submit.

**Scope refinement vs original plan:** the `camera` package (custom
in-app viewfinder, lifecycle handling, permission UI) was deferred. The
system camera via `image_picker` ships the same user value with zero new
native code or lifecycle surface area. A custom viewfinder is a logical
v2 if we want IG/Snapchat-style capture chrome.

**Tradeoff:** drafts referencing local file paths break if the OS purges
the temp dir. `CreateDraftStore` mitigates this by scrubbing missing
paths on load instead of returning a broken draft. v2 could copy the
image into app documents to make drafts fully durable.

---

## Cross-phase: design system additions

Land these incrementally as each phase needs them. All under `lib/ui/`.

| Widget                       | Introduced |
| ---------------------------- | ---------- |
| `CielComposeRow`             | Phase 1    |
| `CielAudiencePickerSheet`    | Phase 1    |
| `CielThumbnail`              | Phase 1    |
| `CielUploadOverlay`          | Phase 2    |
| `CielThumbStrip` (reorder)   | Phase 3    |
| `CielCaptureControls`        | Phase 5    |

Token additions (in `lib/ui/tokens.dart`):

- `CielDurations` — `fast: 120ms`, `normal: 200ms`, `slow: 320ms`.
- `CielElevation` — `floating: 8`, `sheet: 16`.

---

## Test strategy per phase

- **Phase 1:** widget tests for compose screens — empty/photo/error.
- **Phase 2:** notifier tests for state transitions + retry. Fake
  `MediaUseCase` that emits phases on demand.
- **Phase 3:** golden test for the edit toolbar; integration test that
  the cropped bytes are what's uploaded.
- **Phase 4:** golden tests for overlay caption with light and dark
  background images.
- **Phase 5:** notifier tests for draft save/load/discard.

---

## Order & dependencies

```
Phase 1  ──►  Phase 2  ──►  Phase 3  ──►  Phase 4
                                  └────►  Phase 5
```

Phases 4 and 5 are independent of each other after Phase 3.
