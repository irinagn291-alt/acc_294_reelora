# Periplus — Build Specification

> Portfolio app 136, batch pending. This document is the complete brief for
> building this application. Read all of it before writing any code. Anything
> not specified here is your decision, but must stay consistent with section 3.

**One-line positioning:** Log today's reading pages on your book's route.

| Field | Value |
| --- | --- |
| Product name | Periplus |
| Bundle identifier | `com.periplus.route` |
| Domain | https://periplus-route.pro |
| Contact URL | https://periplus-route.pro/contact-us |
| Deployment target | iOS 17.0 |
| Swift version | 6.2, strict concurrency `complete` |
| Devices | iPhone and iPad, portrait |
| Interface style | Dark |
| Asset prefix | `prp_` |
| User-Agent | `Periplus/1.0 (iOS; +https://periplus-route.pro)` |

---

## 1. Non-negotiable constraints

1. **No CocoaPods.** Dependencies come from Swift Package Manager, a local
   in-repo package, a vendored source folder, or nothing at all — per section 3.
2. **No shared code with other portfolio apps.** Business rules are re-implemented
   here under this app's own type names.
3. **All code, identifiers, comments, UI copy and the README are in English.**
4. **No launch gate, no WebView shell, no remote configuration, no analytics.**
   Guideline 4.2 (Minimum Functionality): this is a native SwiftUI product, not
   a web browsing experience. WKWebView / SFSafariViewController as UI is a
   reject. Push notifications, Core Location, and sharing do not make a
   browser or a thin catalog into an App Store app.
5. **Guideline 5.1.1 (Privacy):** never direct the user to grant camera access.
   A pre-permission screen may exist; the proceed button is **Continue** or
   **Next**, never "Allow camera", "Enable camera", "Grant camera", or a bare
   Allow/Enable that triggers `requestAccess`. The system alert is the only Allow.
6. **No CI files.** No `bitrise.yml`, no `Scripts/`, no `metadata/` folder.
7. **Assets are AI-generated.** No stock photography. SF Symbols may support
   small affordances but must never be the primary iconography.
8. **The app must build clean** with
   `xcodegen generate && xcodebuild -scheme Periplus -destination 'generic/platform=iOS' build`.
9. **Nothing may echo another app in this batch** in naming, layout or visuals.
10. **This is not a calorie meal-slot tracker** unless family is `food_tracker`.
   Do not invent food logging to fill the brief.

---

## 2. Product core

The product is offline-first. No account, no sign-in, no ads, no in-app purchase,
no analytics SDK, no remote config. All user data stays on the device.

A reader logs today's leg on the open periplus so the cyanotype route holds toward the volume's landfall.

### 2.1 User flow

1. Log today's pages on the curled cyanotype route
2. Scan or search a volume into the catalogue
3. Open an expedition with a landfall date
4. Watch the route curl when a day passes without a leg
5. Tap Set when drift caps and push landfall forward
6. Review landfalls, legs and buoys in Stats

### 2.2 Essential behaviour

- Cyanotype periplus map as home
- Volume catalogue with ISBN scan and title search
- Leg logging with same-day stack
- Schedule-drift curl visible on the route polyline
- Quartile buoys spawned on crossing
- Set recalibration when drift reaches forty-five degrees
- Local landfall and drift history

---

## 3. Uniqueness assignment for Periplus

| Axis | Assigned value |
| --- | --- |
| Architecture | **Drift projection + Expedition ADT fold (Moored | Underway | Landed); routeX and driftAngle derived from append-only Legs and plannedDays; Buoy at quartile crossings; Set recalibrates Landfall** |
| UI approach | **SwiftUI multi module packages value NavigationStack routing · spritekit-accent** |
| Naming convention | **Periplus / dead-reckoning lexicon (Periplus, Volume, Expedition, Leg, Buoy, Drift, Set, Landfall, Base)** |
| File organization | **By periplus role (Periplus, Volume, Expedition, Leg, Buoy, SetMark, Landfall)** |
| Dependency strategy | **None (zero external dependencies) · no SPM entry, no CocoaPods, no vendored source; UIKit, Core Graphics, AVFoundation and URLSession only** |
| Design direction | **posthog · editorial-stack · mid** |
| Typography | **SF Mono** |
| Navigation pattern | **Periplus-locked chrome (the cyanotype route never leaves; Catalogue, Expedition and Stats arrive as sheets; ISBN scan and title search fuse on Catalogue)** |
| AI art style | **Isometric 3D illustration · collage** |
| Functional twist | **Schedule-drift map (driftAngle = (expectedProgress − routeX) × 45°; idle days curl the route; Log advances routeX; Set recalibrates when drift caps)** |
| Persistence | **CSV** |
| Screen composition | see 3.6 |

### 3.0 Product concept

This is the product the contracts below are assigned to. Do not substitute another.

**Family** — reading_expedition

**Core** — A reader logs today's leg on the open periplus so the cyanotype route holds toward the volume's landfall.

**Audience** — Readers who think in routes and bearings, not percentage bars or genre islands.

**User flow**

1. Log today's pages on the curled cyanotype route
2. Scan or search a volume into the catalogue
3. Open an expedition with a landfall date
4. Watch the route curl when a day passes without a leg
5. Tap Set when drift caps and push landfall forward
6. Review landfalls, legs and buoys in Stats

**Essential features**

- Cyanotype periplus map as home
- Volume catalogue with ISBN scan and title search
- Leg logging with same-day stack
- Schedule-drift curl visible on the route polyline
- Quartile buoys spawned on crossing
- Set recalibration when drift reaches forty-five degrees
- Local landfall and drift history

**Twist** — Schedule-drift map. Home is the cyanotype periplus. Open on a Volume from Catalogue sets a Landfall date and writes an Expedition from Base. Log writes a Leg equal to pages read today, stacks same-day legs, advances routeX by pages divided by totalPages, and spawns a Buoy at each crossed quartile. driftAngle equals expectedProgress minus routeX, times forty-five degrees, clamped zero to forty-five; expectedProgress is elapsed calendar days divided by planned days. The route polyline rotates by driftAngle off true bearing so skipped days curl the course visibly. Log when driftAngle is forty-five or more is refused until Set writes a SetMark that pushes Landfall forward and zeros drift. Set on zero drift is refused. Landfall when routeX reaches one and driftAngle is zero. Seed already opened one Expedition with routeX above zero and drift below forty-five so the opening tap can Log. Home verb: log-the-leg, not bear-the-rhumb and not step-the-token. Stats count Landfalls, Legs and SetMarks. Local only.

**Why this is not a repeat** — First reading_expedition app. Uses craft drift formula on a single-volume cyanotype route. Marteloio spends pages linking genre islands; Cresset walks wake tiles; Margent pins slips on a shelf. Periplus logs legs on one bearing line and makes schedule drift visible as curl—same family screens, different home verb and invariant.

### 3.0a Craft from the shipped portfolio

Full craft is in KNOWLEDGE.md. Follow it. Do not copy type names or layouts.
- Home: Cyanotype route map, not an ISBN shelf.
- Invariant: driftAngle = (lastEndPage/total − progress)×45°. Route x = cumulative pages/total.
- Never: Drift when idle is visible on the map.
- Desk `watch_rate`: OLS s/day vs day; R²; DU/DD/CU/CL/CD spread; COSC |dev|≤4.
- Taste DNA is section 7.6. Do not invent a second look.
- A TabView with exactly three tabs is the factory stamp — use two or four-to-five destinations, or a different chrome. `-ReviewScreen today|log|goals` are launch keys, not tabs.

### 3.1 Architecture contract

An Expedition is a fold of Moored, Underway, or Landed, and the writes are append-only Legs, Buoys, SetMarks, and Landfalls. routeX and driftAngle are projections of those legs and of planned days: routeX equals cumulative pages, with same-day legs summed on one YYYYMMDD key, divided by totalPages, which is lastEndPage divided by total, and driftAngle equals (expectedProgress minus routeX) times 45 degrees, clamped from 0 to 45, where expectedProgress equals elapsed calendar days divided by planned days. The unit test asserts that identity, so an idle day increases driftAngle and the route polyline curls off the true bearing by that angle. A Buoy is appended when routeX crosses one quarter, one half, or three quarters. Set appends a SetMark and moves the Landfall date until expectedProgress equals routeX, which zeros drift, Set is refused while drift is already zero, and Log is refused while driftAngle is 45 degrees or more. Landfall is appended when routeX reaches 1 and driftAngle is 0, which folds Underway to Landed; Moored means no expedition is open, and Open is refused while an expedition is already Underway.

Put a short comment block at the top of each principal type stating the role it
plays in this architecture. The README must justify the pattern for this product.

### 3.2 UI contract

Build the interface in SwiftUI with value-based NavigationStack routing, and keep the periplus role folders as modules inside the single app target. SpriteKit is the one custom accent: an SKView on Map draws the route polyline, the quartile buoys, and the drift rotation, and every sheet stays stock SwiftUI. Colours, type, space, and the 32 and 16 point radii come from one accessor each, with hairline plus fill elevation and a bordered-prominent primary ButtonStyle that includes default, pressed, disabled, and loading, plus a destructive style for reset. Motion stays quiet, a 180 millisecond ease-out cross-fade, numbers that tick, and an instant swap when Reduce Motion is on, so the curl sets its angle without travel. The map is the wide hero and sheet prose stays in a narrow measure. Hit targets fill the control to at least 44 points with contentShape, and every icon-only control has a VoiceOver label.

### 3.3 Naming contract

Convention: Periplus / dead-reckoning lexicon (Periplus, Volume, Expedition, Leg, Buoy, Drift, Set, Landfall, Base).

Examples to follow: `Volume`, `logLeg(pages:dayKey:)`, `SetMark`, `driftAngle`

### 3.4 Dependency contract

Zero external dependencies. No SPM package entry, no CocoaPods, no vendored source, and no packages key in project.yml. System frameworks only: SwiftUI, UIKit, Core Graphics, AVFoundation, SpriteKit, and URLSession. SpriteKit draws the route, AVFoundation captures ISBN barcodes, and URLSession performs Open Library title and ISBN lookups with User-Agent Periplus/1.0 (iOS; +https://periplus-route.pro). Do not call Open Food Facts. Role folders compile into the single Periplus target.

### 3.5 Navigation contract

The route on Map stays mounted at the root. Catalogue, Expedition, Stats, and Settings arrive as sheets. ISBN scan and title search are controls on the Catalogue sheet. There is no tab bar. Launch keys are not tabs: today shows Map, log shows Stats, goals shows Expedition, catalogue shows Catalogue, and settings shows Settings. ProcessInfo arguments are read once, and only after onboarding has finished.

### 3.6 Screen composition contract

Physical screens: Map, Catalogue, Expedition, Stats, Settings. Map fills the iPhone and the iPad width with the SpriteKit route, the open volume title, today's pages, the drift figure, and a full-width Log control. Catalogue, Expedition, Stats, and Settings are sheets on that root. Onboarding is three or four pages with a full-width Next or Continue at the bottom, then it leaves the chrome. The launch argument today opens Map with Log enabled. The launch argument log opens Stats. The launch argument goals opens Expedition. The arguments catalogue and settings open Catalogue and Settings. Map empty state is a full page reading: No expedition yet. Open a volume. Catalogue empty state and Stats empty state are full pages, each with generated art, one headline, one line, and one full-width action. Catalogue fuses title search and ISBN scan. Title search uses URLSession GET https://openlibrary.org/search.json with q, limit, and fields, debounced about 500 milliseconds, cancelling the previous task. An empty query does not hit the network. An ISBN lookup uses https://openlibrary.org/isbn/ and the code. Missing pages, a transport failure, or an empty result opens a manual title and total-pages form on the local shelf, and saved volumes still filter offline. A duplicate ISBN updates the existing volume. Expedition picks a Landfall date and writes the voyage from Base. Stats counts Landfalls, Legs, and SetMarks with NumberFormatter, one hero figure and then a varied list. Settings holds re-run onboarding, a confirmed reset that names the deleted route, and the contact link https://periplus-route.pro/contact-us. Seeded Simulator home shows one named volume, four legs, a crossed buoy, routeX above zero, and drift below 45 degrees.

Section 5 lists the logical functions that must exist. This section decides how
they are grouped into actual screens. Where the two disagree, this section wins.

A TabView with exactly three tabs is the factory stamp — use two or four-to-five destinations, or a different chrome. `-ReviewScreen today|log|goals` are launch keys, not tabs.

---

## 4. Target file organization

Scheme: **By periplus role (Periplus, Volume, Expedition, Leg, Buoy, SetMark, Landfall)**

```
Periplus/
  Periplus/
  PeriplusStore.swift
  RouteProjection.swift
  DayKey.swift
  CsvStore.swift
  MapScreen.swift
  RouteScene.swift
  StatsSheet.swift
  SettingsSheet.swift
  OnboardingScreen.swift
  PeriplusColor.swift
  PeriplusFont.swift
  PeriplusSpace.swift
  PeriplusButton.swift
Volume/
  Volume.swift
  CatalogueSheet.swift
  IsbnCapture.swift
  TitleSearch.swift
Expedition/
  Expedition.swift
  ExpeditionFold.swift
  ExpeditionSheet.swift
Leg/
  Leg.swift
  LogLeg.swift
Buoy/
  Buoy.swift
SetMark/
  SetMark.swift
Landfall/
  Landfall.swift
  Assets.xcassets/
```

Adapt the leaf files to the architecture, but the top-level shape is fixed. Do
not create a `Utils/` or `Helpers/` dumping ground.

---

## 5. Screens

Build the screens named in section 3.6. The labels below are logical;
actual type names follow this app's naming convention.

### 5.1 Onboarding
Three to four pages. Explains the product, writes initial settings, sets a
completion flag. Skip still writes sensible defaults. Re-runnable from Settings.

### 5.2 Map
A first-class screen for **Map**. Must render empty, populated and error states.

### 5.3 Catalogue
A first-class screen for **Catalogue**. Must render empty, populated and error states.

### 5.4 Expedition
A first-class screen for **Expedition**. Must render empty, populated and error states.

### 5.5 Stats
A first-class screen for **Stats**. Must render empty, populated and error states.

### 5.6 Settings
A first-class screen for **Settings**. Must render empty, populated and error states.

### 5.7 Settings
Holds: re-run onboarding, reset all data (confirmed), and the contact link to
the domain contact-us URL.

### 5.8 Twist screen
See section 12. The twist needs at least one screen of its own plus a surface on the home screen.


---

## 6. Domain model

Minimum entities, named per this app's convention:

- **Volume** — named per this app's convention.
- **Expedition** — named per this app's convention.
- **Waypoint** — named per this app's convention.
- Plus whatever the twist in section 12 requires.


---

## 7. Design system

Direction: **posthog · editorial-stack · mid**

### 7.1 Palette

| Token | Hex | Use |
| --- | --- | --- |
| `background` | `#34373D` | Screen background |
| `surface` | `#42454D` | Cards, rows, sheets |
| `ink` | `#F4F4F6` | Primary text and icons |
| `accent` | `#6D95E3` | Primary action, key figure, progress fill |
| `muted` | `#B6BAC3` | Secondary text, dividers, disabled |

Define these as named colours in `Assets.xcassets` and reach them through one
typed accessor. Never hard-code a hex string anywhere else.

### 7.2 Typography

Family: **SF Mono**

SF Mono is the assigned face, reached as Font.system with the monospaced design. Mono numerals carry pages, route figures, drift degrees, day keys, and Stats counts through NumberFormatter. The humanist body is sentence-case SF Mono at the body step, about 17 points at the default size, with comfortable leading and complete sentences. The type move is mono numerals, humanist body, no poster type, warm. At most six steps sit behind one accessor: display, title, headline, body, caption, micro. No Font.custom with a fixed size. Sizes track Dynamic Type, stay at least 12 points, and a headline still reads at the largest accessibility size.

Define a type scale of at most six steps behind one accessor and use only those
steps. Text stays legible at the largest Dynamic Type size.

### 7.3 Layout

- One base spacing unit (4 or 8 pt); only multiples of it.
- Corner radius and elevation are fixed by section 7.4, not chosen per screen.
- Every interactive element is at least 44x44 pt.

### 7.4 Component contract

Corner radius: **32pt** for cards, sheets and primary surfaces; **16pt** for chips, badges and small controls. Reach both through one accessor. Never a bare literal number, and never zero — a hard edge is not this app's design direction.

Elevation: **hairline+fill** — a 1pt hairline border plus a flat fill tint, reused everywhere a surface sits above another.

Primary control: **bordered prominent** — primary actions use `.buttonStyle(.borderedProminent)` or an equivalent filled, bordered shape.

This is arithmetic, not a suggestion: every card, sheet, chip and button in this app uses these two radii and this elevation style. Do not introduce a second radius or a second elevation style.

### 7.5 Custom rendering scope

This app's `ui` axis is **SwiftUI multi module packages value NavigationStack routing · spritekit-accent**.

If that approach uses anything beyond stock SwiftUI/UIKit controls — `Canvas`, `CALayer`, Metal, SceneKit, SpriteKit, RealityKit, a hand-drawn `UIViewRepresentable`, or any other pixel-level custom rendering — confine it to exactly one hero surface on one screen (the mechanic's home view, or the one screen this axis exists to showcase). Every other screen — every list, every settings screen, every sheet, every secondary surface — is built from stock components: `List`, `Form`, `NavigationStack`, `TabView`, `Button`, `.sheet`, native `Text`/`Image`. A second custom-rendered surface elsewhere in the app is a defect, not a stylistic choice.

If **SwiftUI multi module packages value NavigationStack routing · spritekit-accent** is already fully native (no custom drawing layer), this section is satisfied automatically — there is nothing to confine.

The `ui` axis value is an implementation choice. It must never appear as a user-visible section title or label.

### 7.6 Taste DNA

Aesthetic: **warm** (Warm soft: friendly radii, comfortable pad, one playful moment.)

Reference system: **posthog** — steal rhythm and restraint, not their colours or logos.

Mood: **Product analytics. Playful hedgehog branding, developer-friendly dark UI.**.

Home rhythm (`editorial-stack`, comfortable): Narrow measure for prose, wide for media. Rules, not boxes.

Warm soft: friendly radii, comfortable pad, one playful moment. Layout `editorial-stack`, density comfortable. Kit 32/16, hairline+fill, bordered prominent. Palette recipe `mid`. Almost no travel. Cross-fade 180ms ease-out. Numbers tick, they do not fly. Reduce Motion: instant swap. Reduce Motion: fade only. Do not invent a second radius or a second accent.

Type move: Mono numerals, humanist body, no poster type. Reference type feel: warm.

Motion (`quiet`): Almost no travel. Cross-fade 180ms ease-out. Numbers tick, they do not fly. Reduce Motion: instant swap.

Voice (`editorial`): Complete sentences, no slang, no hype. Captions are real lines.

Anti-slop from KNOWLEDGE.md applies. Taste never overrides contrast, 44pt hits, VoiceOver labels, or Reduce Motion.

---

## 8. UI and UX quality bar

Every item here is a defect if it is missing. Do not treat this as advice.

**Layout**

- Respect safe areas on every screen. Nothing sits under the notch, the Dynamic
  Island or the home indicator.
- The app is portrait-only on iPhone. Lock it in the Info settings and do not
  write rotation-dependent layout.
- No layout shift when asynchronous data arrives. Reserve the final size up
  front, or use a redacted placeholder of the same dimensions.
- Long product names must truncate gracefully, never push a number off screen.
  Numbers win; names truncate.
- Sibling cards, images and titles never overlap. Each cell owns its frame;
  `scaledToFill` is clipped to that cell. A chopped headline or two canvases
  in one slot is a defect, not a collage.
- Minimum tap target 44x44 pt for every interactive element, including small
  icon buttons and list accessories.
- Pick one base spacing unit and use only multiples of it. No arbitrary values.

**Keyboard**

- The grams field uses `.decimalPad`, and the decimal separator matches the
  user's locale.
- Content scrolls out from under the keyboard. The focused field is always
  visible.
- Tapping outside the field, or scrolling, dismisses the keyboard.
- Validate on the fly: reject negative and non-numeric input rather than
  crashing the parser later.

**Loading and state**

- Every asynchronous operation has a visible loading state.
- Guard against the spinner flash: if the work finishes in under 150 ms, do not
  show a spinner at all.
- Every list has a designed empty state containing a primary action, not just a
  sentence of text.
- Every error state offers a retry, and states plainly what failed.
- Disable the primary button while its action is in flight so it cannot be
  double-tapped into a double push or a duplicate entry.

**Typography and accessibility**

- All text scales with Dynamic Type. Verify at the largest accessibility size:
  nothing may clip or overlap.
- Every icon-only control has an `accessibilityLabel`. Decorative images are
  marked as decorative so VoiceOver skips them.
- Colour is never the only signal. Pair it with a label, a shape or an icon.
- Honour Reduce Motion: replace movement-heavy transitions with a fade.
- Meet contrast requirements against the palette in section 7. Check the muted
  colour against the background specifically; that is where these palettes fail.

**Formatting**

- Format every number with `NumberFormatter`, never string interpolation. Group
  separators and decimal separators must follow the locale.
- Energy is shown as a whole number of kcal. Macros are shown with at most one
  decimal place.
- Round only at the point of display. Stored values keep full precision.
- Day boundaries use `Calendar.current.startOfDay(for:)` in the user's current
  time zone. Handle the day changing while the app is open, and handle the
  short and long days that daylight saving produces.
- Unknown macro values render as a dash or the word "unknown", never as 0.

**Motion and feedback**

- One haptic on a successful commit (a food logged, a target saved). No haptic
  on navigation.
- Animations are short (0.2 to 0.35 s) and use a single shared easing curve.
- Nothing animates on first appearance of a screen except an intentional entry
  transition.

**Navigation**

- Back always works and never loses entered data without asking.
- A destructive action (delete a log row, reset all data) is confirmed.
- Modal sheets can always be dismissed; there is no dead end.
- Deep state is restorable: relaunching returns the user to a sane screen.


Every item here is a defect if it is missing. Section 7.4 fixed the numbers —
this is where they have to show up on screen.

**Hierarchy and density**

- Every screen has exactly one dominant element (a hero number, a canvas, a
  primary card) that the eye lands on first. A screen where every element has
  equal weight reads as a spreadsheet, not a product.
- Related content is grouped into a card or a section with the elevation
  style from 7.4, not left floating on the bare background.
- Unused flat background is not "minimal" — see the density rule in
  `KNOWLEDGE.md`. If a screen has room left after the mechanic and the
  content, add a secondary surface (a stat strip, a recent-activity card, a
  related-item row), not a `Spacer`.

**Components**

- Every card, sheet, chip, row and button in the app uses the corner radius
  and elevation from section 7.4. No screen introduces its own radius or its
  own shadow value "just for this one card".
- Buttons have a pressed state (`ButtonStyle` with a scale or opacity change
  on `isPressed`) and a disabled state that is visibly different, not just
  non-interactive.
- Chips and badges are pill or rounded-rect shaped per 7.4, never a bare
  `Text` with no background sitting where a control is expected.
- A functional control (add, filter, sort, close, more, share, delete) is an
  SF Symbol inside a properly hit-targeted `Button`. SF Symbols are fine and
  expected here — section 16 only bans them as the app's primary brand
  iconography (app icon, empty-state hero, onboarding art), which is what the
  generated assets in section 13 are for.

**Depth and material**

- At least one surface in the app (a sheet, a modal, a floating toolbar) uses
  the elevation style from 7.4 to visibly sit above the content behind it.
  A flat app with no depth anywhere reads as a wireframe.
- Icons and generated art sit on the surface colour from 7.1, never directly
  on a colour that makes their edges disappear.

**Motion as feedback, not decoration**

- The one dominant element in a screen (7.4's primary control, the mechanic's
  hero) responds visibly to touch: a scale, a colour shift, a haptic — pick
  at least one. A control that looks identical pressed and unpressed reads as
  broken, not calm.

**Taste DNA (section 7.6)**

- Home uses the assigned layout family and density. Three identical equal-weight
  cards, a leftover bento hole, or a second column structure copied down the
  page is a defect.
- Copy follows the assigned voice. No em-dash, no elevate/unlock/seamless, no
  emoji, no SECTION 01 labels.
- Motion follows the assigned personality and honours Reduce Motion with a fade.
  One signature motion per view. No glow stacked on glass stacked on spring.
- Tokens by intent: the live verb wears accent; delete does not wear primary.


---

## 9. Concurrency

The target builds with Swift 6.2 and `SWIFT_STRICT_CONCURRENCY = complete`. It
must compile with **zero concurrency warnings**. Warnings here become crashes
later, so they are not negotiable.

- All UI types are `@MainActor`. Annotate the type, not individual methods.
- Any value crossing an actor boundary is `Sendable`. Prefer immutable structs
  of primitives.
- Do not use `@unchecked Sendable`. If it is genuinely unavoidable, it needs a
  comment explaining what guarantees the safety.
- No mutable global state. No `static var` that is written after launch.
- Networking and storage APIs are `async` and honour cancellation. When the
  search query changes, cancel the in-flight task; do not let a stale response
  overwrite fresh results.
- Use structured concurrency. Avoid `Task.detached` unless there is a stated
  reason. Never fire a `Task` that outlives the view without owning it.
- Never use `DispatchQueue.main.asyncAfter` to paper over an ordering problem.
  Fix the ordering.
- `Timer` and notification observers are invalidated in `deinit` or on
  disappear.


---

## 10. Persistence engineering

Chosen technology: **CSV**

CSV files under Application Support are the projection of an in-memory PeriplusStore. manifest.csv holds schemaVersion from 1. volumes.csv, expeditions.csv, legs.csv, buoys.csv, setmarks.csv, and landfalls.csv hold the append-only records. Day keys are Int values in YYYYMMDD form taken from Calendar.current.startOfDay. routeX, driftAngle, and expectedProgress are derived on read and are not trusted from disk. Writes are atomic, off the main thread, debounced, and flushed when scenePhase becomes inactive or background. A decode failure restores the previous good files, and if those also fail the store starts empty and tells the reader. resetAllData() deletes the folder and is reachable from Settings. Views never touch FileManager. Simulator seed runs once behind prp.demo.v1, marks onboarding complete, and writes one named volume, one Underway expedition, four legs with routeX above zero, one buoy, and drift below 45 degrees so Log is enabled. Never seed on a device.

This app persists to **files on disk**. The following are mandatory.

- Write atomically. Either `Data.write(to:options: .atomic)` or write to a
  temporary file and `FileManager.replaceItemAt`. A non-atomic write that is
  interrupted leaves a truncated file and the app will not launch.
- Create the containing directory with
  `withIntermediateDirectories: true` before the first write.
- Every document carries a `schemaVersion` field from version 1, and the decoder
  switches on it.
- Decoding failure must be recoverable: keep the previous good file as a
  `.backup`, fall back to it, and if that also fails start from empty state and
  tell the user. Never crash on a corrupt file.
- All file IO happens off the main thread. The main thread never blocks on disk.
- Debounce writes during rapid edits, but force a flush when `scenePhase`
  becomes `.inactive` or `.background`, and after any destructive action.
- Exclude caches from backup with `URLResourceValues.isExcludedFromBackup` where
  appropriate; user data belongs in Application Support and should be backed up.
- Keep an explicit in-memory source of truth and treat the file as a projection
  of it, so a failed write never leaves the UI showing data that does not exist.


Regardless of technology:

- One seam between domain logic and storage; the UI never touches storage types.
- Writes survive a force-quit. Do not rely on `applicationWillTerminate`.
- Provide `resetAllData()`, used by tests and reachable from Settings.

---

## 11. Networking

- One client type owns both Open Food Facts endpoints.
- Set `User-Agent` on every request. Open Food Facts throttles clients that do
  not identify themselves.
- 15 second timeout. One retry on a transient transport failure, then a typed
  error. Do not retry a 404.
- Cancel the in-flight search when the query changes. Debounce input by roughly
  300 ms.
- Decode into DTO types that mirror the JSON exactly, then map to domain types.
  Never decode straight into your domain model.
- Dedicated `JSONDecoder` with `.useDefaultKeys`. Never `convertFromSnakeCase` —
  Open Food Facts keys like `energy-kcal_100g` break snake_case conversion.
- Resolve a scanned code with `GET /api/v2/product/<barcode>.json`, not a search.
- Open Food Facts data is user-contributed and frequently incomplete. Every
  numeric field is optional. A product with no energy value is a normal case
  that the UI must present, not an error.
- Some numeric fields arrive as strings. The decoder must accept both a number
  and a numeric string for every nutriment.
- `status` of `0` in the product response means not found. Map it to a distinct
  error case so the UI can offer manual entry.
- Never crash on malformed JSON. A decoding failure is a handled error.
- Cache every resolved product locally on success, so the app degrades to a
  working offline catalogue.


Set `User-Agent: Periplus/1.0 (iOS; +https://periplus-route.pro)` on every request. Never reuse another app's string.
No required remote catalog. Network only if this product actually needs it.

---

## 11b. App Store readiness

The app must be submittable without further work.

- `PrivacyInfo.xcprivacy` in the target, declaring the UserDefaults access API
  reason `CA92.1` and the file timestamp reason `C617.1`, with
  `NSPrivacyTracking` false and no collected data types.
- `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` in the pbxproj so TestFlight
  does not sit on Missing Compliance.
- `NSCameraUsageDescription` written specifically for this app. Generic strings
  get rejected.
- `LSApplicationCategoryType` of `public.app-category.healthcare-fitness`.
- Portrait only, iPhone and iPad (`TARGETED_DEVICE_FAMILY = "1,2"`).
- No account, no sign-in, no delete-account flow, no in-app purchase, no ads, no
  user-generated content, and therefore no report or block UI.
- App Tracking Transparency is never invoked.
- The camera is the only sensitive permission requested.
- Guideline 5.1.1 (Privacy): do not encourage or direct the user to grant camera
  access. A pre-permission screen may exist, but the proceed button must be
  **Continue** or **Next** — never "Allow camera", "Enable camera",
  "Grant camera", or a bare Allow/Enable that calls `requestAccess`. The
  system dialog is the only Allow. Denied/restricted offers Open Settings.
- The app must not present itself as a clinician or as medical advice.
- Guideline 4.2 (Design — Minimum Functionality): the binary must be a native
  product, not a web browsing experience. No WKWebView / SFSafariViewController
  / UIWebView as home, a tab, or the primary UX. A content catalog, article
  reader, or site wrapper that could be a website is a reject. Push
  notifications, Core Location, and sharing do not make that acceptable.
- Guideline 1.4.1 (Safety — Physical Harm): if the binary shows health or
  medical recommendations, body-based targets, dosages, "you should" guidance,
  or product health claims (food, drink, supplement, remedy), put citations
  in the app. Tappable links to the sources, easy to find: same screen as the
  claim, or a Sources row one tap from Settings. Name the source (Open Food
  Facts, USDA FoodData Central, WHO, NIH MedlinePlus, …) and link it. A
  "not medical advice" footer without sources is a reject. A personal log
  that never advises does not invent claims to cite.
- Nutrition catalog data is credited to the database this app actually uses
  (Open Food Facts unless the spec names another). Credit is a tappable link,
  not a dead "OpenFoodFacts" label.


Ignore the food-log and Open Food Facts lines above when they conflict with this
family. Category for this app is `public.app-category.books`. Camera permission only if the
product actually captures.

Project settings that follow from the above:

```yaml
INFOPLIST_KEY_UIUserInterfaceStyle: Dark
INFOPLIST_KEY_UISupportedInterfaceOrientations: UIInterfaceOrientationPortrait
INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad: UIInterfaceOrientationPortrait
INFOPLIST_KEY_UIRequiresFullScreen: YES
INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO
INFOPLIST_KEY_LSApplicationCategoryType: public.app-category.books
TARGETED_DEVICE_FAMILY: "1,2"
SWIFT_STRICT_CONCURRENCY: complete
```

---

## 12. Functional twist: Schedule-drift map (driftAngle = (expectedProgress − routeX) × 45°; idle days curl the route; Log advances routeX; Set recalibrates when drift caps)

Home is the periplus map, and the persisted verb on that map is Log. Log writes a Leg of pages read today, stacks any leg that shares the same YYYYMMDD day key, advances routeX by pages divided by totalPages, and appends a Buoy at each quartile the leg crosses. driftAngle equals (expectedProgress minus routeX) times 45 degrees, clamped from 0 to 45, and the route polyline rotates by that angle so a day without a leg curls the course on the map. Log at 45 degrees or more is refused until Set writes a SetMark, pushes Landfall forward, and zeros drift. Set at zero drift is refused, and Landfall is recorded when routeX reaches 1 and driftAngle is 0. The Simulator seed opens one Underway expedition with routeX above zero and drift below 45 degrees, so the first tap can Log.

This is the app's marketed differentiator. It must be:

- visible on the home screen, not buried in settings;
- backed by real persisted data, not a cosmetic flourish;
- covered by at least one unit test;
- described in the README as the reason a user would pick this app.

---

## 13. AI-generated assets

Art style: **Isometric 3D illustration · collage**


Base prompt, reused and extended for every asset:

```
Isometric 3D illustration assembled as a paper collage. Solid volumes with thickness, layered cut paper, chart instruments, and one book-like mass. Quiet expedition mood, warm and editorial, with a single playful curl in a thick paper ribbon. No text, no letters, no glyphs, no poster type. Pigments come from the app palette, so this prompt names none.
```

All 12 images below are required. Generate each one, export
as PNG, and add it to `Assets.xcassets` as its own image set named exactly as
given. Every name carries the `prp_` prefix.

### 13.1 App icon rules (strict)

The icon is rejected by App Store Connect if any of these are wrong:

- Exactly **1024 x 1024 px**.
- **No alpha channel.**
- sRGB colour profile, 8 bits per channel, PNG.
- **No text and no words** in the artwork.
- **No rounded corners and no built-in mask.**
- The subject stays inside the middle 80%.

### 13.2 Full asset list

| # | Image set | Size (px) | Alpha | Purpose |
| --- | --- | --- | --- | --- |
| 1 | `prp_AppIcon` | 1024x1024 | **NO** | App Store icon. NO alpha channel, NO transparency, NO text, NO rounded corners, NO drop shadow outside the canvas. |
| 2 | `prp_Splash` | 1290x2796 | fill | Launch background. The middle third must stay quiet so the wordmark reads on top. |
| 3 | `prp_Onboarding1` | 1024x1536 | **required cutout** | Onboarding page 1 illustration: what the app is for. |
| 4 | `prp_Onboarding2` | 1024x1536 | **required cutout** | Onboarding page 2 illustration: the main verb. |
| 5 | `prp_Onboarding3` | 1024x1536 | **required cutout** | Onboarding page 3 illustration: why they stay. |
| 6 | `prp_EmptyHome` | 1024x1024 | **required cutout** | Empty state: the home screen has nothing yet. Calm and inviting, never sad. |
| 7 | `prp_EmptyList` | 1024x1024 | **required cutout** | Empty state: a secondary list has no rows. |
| 8 | `prp_CardBackdrop` | 1200x800 | fill | Backdrop art for a primary card. Low contrast so text stays readable. |
| 9 | `prp_ControlFace` | 512x512 | **required cutout** | Custom control artwork used for the primary interactive element. |
| 10 | `prp_TwistHero` | 1024x1024 | **required cutout** | Hero art for the 'Schedule-drift map (driftAngle = (expectedProgress − routeX) × 45°; idle days curl the route; Log advances routeX; Set recalibrates when drift caps)' feature screen. |
| 11 | `prp_SuccessMark` | 512x512 | **required cutout** | Shown briefly when the primary action succeeds. |
| 12 | `prp_HeaderDecor` | 1200x600 | **required cutout** | Decorative header accent on the main screen. |

### Prompt per asset

**`prp_AppIcon`** — 1024x1024

```
Isometric 3D paper collage. One solid emblem of a closed book fused with a thick curling paper ribbon, centered and filling the canvas edge to edge. Opaque, no text, no letters, no rounded mask, no shadow outside the canvas. Keep the subject inside the middle 80 percent.
```

**`prp_Splash`** — 1290x2796

```
Isometric 3D paper collage, vertical, filling the canvas. A quiet uncluttered centre band of layered paper, with a small solid book and a thick ribbon sitting low. The middle third stays empty of detail so a wordmark can be placed later. No text in the image.
```

**`prp_Onboarding1`** — 1024x1536

```
Isometric 3D paper collage of a solid closed book resting on a folded chart, readable in one glance as a reading route. Thick opaque subject, centered.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`prp_Onboarding2`** — 1024x1536

```
Isometric 3D paper collage of a solid page block being set onto a thick paper route, the log gesture caught mid motion. Opaque subject, centered.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`prp_Onboarding3`** — 1024x1536

```
Isometric 3D paper collage of a thick paper route that has curled and arrived beside a solid finished book and a solid landfall marker. Opaque subject, centered.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`prp_EmptyHome`** — 1024x1024

```
Isometric 3D paper collage of a solid closed chart folio with a clasp, calm and waiting. Fully opaque paper mass, centered, not glass and not a hollow frame.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`prp_EmptyList`** — 1024x1024

```
Isometric 3D paper collage of a solid closed crate packed with blank paper signatures. Opaque subject, centered, not a wire shelf.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`prp_CardBackdrop`** — 1200x800

```
Isometric 3D collage of broad paper planes filling the whole canvas, low contrast, abstract, quiet enough for type to sit on top. No text.
```

**`prp_ControlFace`** — 512x512

```
Isometric 3D paper collage of one solid physical knob, thick and opaque, the face of the Set control. Centered, not a ring and not a hollow bezel.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`prp_TwistHero`** — 1024x1024

```
Isometric 3D paper collage of a thick solid paper ribbon curling off a straight bearing, with one solid book at its start. The ribbon has body. Centered, opaque.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`prp_SuccessMark`** — 512x512

```
Isometric 3D paper collage of a solid buoy with a full opaque body, a confirmation emblem. Centered.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`prp_HeaderDecor`** — 1200x600

```
Isometric 3D paper collage of a wide thick paper ribbon ornament, solid and centered, opaque.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```


### 13.3 Asset rules

- Cut-outs (everything except AppIcon, Splash, CardBackdrop): isolated subject,
  real PNG alpha, all four corners transparent. No square plate.
- Assets must be semantically different from each other.
- Record the exact prompt used for every asset in the README.
- SF Symbols are permitted only for close, chevron, share and similar system
  affordances.

Scanner frames, reticles, and seamless tiles are drawn in SwiftUI via `Path` or `Shape`. GenerateImage is not used for those. Every other in-app graphic (except AppIcon, Splash, CardBackdrop) is a **cutout**: isolated SOLID opaque subject in the center, real PNG alpha, all four corners transparent. An opaque square plate inside a circle or pentagon is a fail. A hollow glass box or wire frame with a transparent center is a fail.

---

## 14. Demo data

Seed a small local demo dataset for this family's entities so Simulator
screenshots are not empty. The same seed must mark onboarding complete and
fill the primary surface — otherwise `-ReviewScreen` never fires. Never seed
on a physical device. Guard with `#if targetEnvironment(simulator)` and
`prp.demo.v1`.

Seed the happy path: the home primary verb is enabled. The blocked / gated /
error state is a unit-test fixture, not Simulator home. Home chrome names the
job and the next tap in words a stranger knows. Axis values (`ui`, `naming`,
`architecture`) never become user-visible titles. A card that looks tappable
is a `Button`. A readout does not use button chrome.

---

## 16. Anti-patterns

The following will fail review:

- `try!`, `as!`, or force-unwrapping anything derived from the network, the
  database or a file.
- `fatalError` anywhere reachable at runtime. It is acceptable only for a
  programmer error in an initialiser that cannot fail in practice, and needs a
  comment.
- Swallowing an error with an empty `catch`.
- `print` used as production logging.
- A hard-coded hex colour outside the single colour accessor.
- A hard-coded font name outside the single typography accessor.
- An SF Symbol used as the app's brand iconography — the app icon, the
  empty-state hero, or onboarding art. Those come from section 13. SF Symbols
  are the right choice for every functional control (add, filter, sort,
  close, share, delete) — leaving those as bare text instead of a symbol is
  also a defect.
- Storing a value that can be computed (day totals, remaining budget, macro
  percentages).
- Blocking the main thread on disk or network work.
- `UIScreen.main` for sizing. Use the geometry the layout system gives you.
- Index positions used as list identity. Identity is a stable identifier.
- A view that reaches into the persistence layer directly, bypassing the
  architecture's designated seam.
- Business logic inside a `View` body or a `UIViewController` method, when the
  assigned architecture places it elsewhere.
- Copying a source file from another app in this batch.
- A `TabView` with exactly three tabs. That is the factory stamp — two or
  four-to-five destinations, or a different chrome. ReviewScreen keys are
  not tabs.


---

## 17. Tests

Add a unit test target `PeriplusTests` covering at minimum:

1. The core domain invariant of this family (the thing that would be wrong if
   the calculator, decay, crate, or log lied).
2. Empty, populated and invalid input paths for the primary verb.
3. The section 12 twist logic.
4. One architecture-specific test proving the pattern holds.
5. A persistence round-trip: write, relaunch-equivalent reload, verify.
6. Parse `ProcessInfo.processInfo.arguments` once after onboarding. 
   `-ReviewScreen today|log|goals` switches the running app's live navigation. Extra cover slugs open those screens.
   Cover that parser with a unit test. Do not host a `View` in the test.

---

## 18. README.md

Write `README.md` at the app folder root covering:

1. What the app does and who it is for.
2. The architecture used and **why** it suits this product.
3. The unique feature added and how it works.
4. The AI art style and the exact prompt used for every asset.
5. How this app differs from others in the batch.
6. Build instructions.

---

## 19. Definition of done

**Build**
- [ ] `xcodegen generate` succeeds.
- [ ] `xcodebuild -scheme Periplus -destination 'generic/platform=iOS' build` succeeds.
- [ ] Zero new compiler warnings.
- [ ] Strict concurrency `complete` compiles clean.
- [ ] Test target passes.

**Function**
- [ ] Onboarding to first successful primary action works on a clean install.
- [ ] Every screen in section 3.6 exists and handles empty / filled / error.
- [ ] Reset and contact link live in Settings.
- [ ] Force-quitting immediately after a write loses nothing.
- [ ] Seeded home names the job and next tap; primary verb enabled.
- [ ] App reads `-ReviewScreen today|log|goals` after onboarding.

**Uniqueness**
- [ ] Architecture matches **Drift projection + Expedition ADT fold (Moored | Underway | Landed); routeX and driftAngle derived from append-only Legs and plannedDays; Buoy at quartile crossings; Set recalibrates Landfall** with no leakage across layers.
- [ ] UI approach matches **SwiftUI multi module packages value NavigationStack routing · spritekit-accent**.
- [ ] Custom rendering, if any, is confined to one hero surface (section 7.5).
- [ ] Navigation matches **Periplus-locked chrome (the cyanotype route never leaves; Catalogue, Expedition and Stats arrive as sheets; ISBN scan and title search fuse on Catalogue)**.
- [ ] Screen composition follows section 3.6.
- [ ] Typography uses **SF Mono** and nothing else.
- [ ] Palette matches section 7.1 exactly.
- [ ] Home rhythm and motion match section 7.6. No second look.

**Quality**
- [ ] Section 8 UI/UX bar satisfied end to end.
- [ ] Contact link present.
- [ ] `PrivacyInfo.xcprivacy` present and correct.
- [ ] README complete.

---

## 20. Build commands

```bash
cd Periplus
xcodegen generate
xcodebuild build-for-testing -scheme Periplus -destination 'generic/platform=iOS Simulator' -jobs 2 CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO -derivedDataPath '/Users/belzephyrus/Documents/gambling-factory/.artifacts/genesis/com.periplus.route/DerivedData' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
xcodebuild -scheme Periplus -destination 'generic/platform=iOS' -jobs 2 CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO -derivedDataPath '/Users/belzephyrus/Documents/gambling-factory/.artifacts/genesis/com.periplus.route/DerivedData' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build
xcrun simctl list devices available
xcodebuild test-without-building -scheme Periplus -destination 'platform=iOS Simulator,id=<UDID>' -jobs 2 -derivedDataPath '/Users/belzephyrus/Documents/gambling-factory/.artifacts/genesis/com.periplus.route/DerivedData'
```

Signing is off only on that command line. Do not put CODE_SIGNING_ALLOWED, CODE_SIGNING_REQUIRED, CODE_SIGN_IDENTITY, DEVELOPMENT_TEAM, SWIFT_TREAT_WARNINGS_AS_ERRORS or -derivedDataPath in project.yml — they are command-line only. CI signs the archive. Leave CODE_SIGN_STYLE: Automatic as the scaffold set it. The exact simulator does not matter — use any available UDID from the list.
