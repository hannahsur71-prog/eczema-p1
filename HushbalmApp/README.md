# Hushbalm design system (SwiftUI)

The foundation for the Hushbalm iOS app (working name): a screen-free bedtime
moisturizer-massage and story ritual for families with eczema. Built first,
before any app screens, so every screen shares one look.

Requires iOS 17+, Swift 5.9+, Xcode 15+.

## Install
In Xcode: **File › Add Package Dependencies… › Add Local…** and pick this
`HushbalmApp` folder, then `import HushbalmDesignSystem`.
Open `HBCatalogView.swift` and use the canvas preview to see everything.

## Typography: one family, eight styles
Every piece of text uses **SF Pro Rounded** (Apple's system font, rounded design).
No other fonts. All styles scale with Dynamic Type.

| Style | Base size | Weight | Use |
|---|---|---|---|
| `.display` | 34 | Heavy | Hero headline, max one per screen |
| `.title` | 28 | Heavy | Screen titles |
| `.title2` | 22 | Bold | Ritual step titles |
| `.headline` | 17 | Bold | Section headers, card titles, primary buttons |
| `.body` | 17 | Regular | Paragraphs, instructions |
| `.callout` | 16 | Semibold | Chips, row titles, secondary buttons |
| `.footnote` | 13 | Regular | Supporting text |
| `.label` | 12 | Bold, uppercase, tracked | Eyebrows and badges |

Rules:
1. Style text only with `.hbText(_:color:)`. Never `.font(...)` in app code.
2. Need a new style? Add it to `HBTextStyle`, not to a screen.
3. `scripts/check-fonts.sh` fails if app code uses `.font(`, `Font.custom` or `UIFont`.

## Color
Dark-first (used at bedtime). Tokens in `HBColor`; no raw hex in screens.

| Token | Hex | Use |
|---|---|---|
| `background` | #0E1430 | Screen background |
| `surface` | #182046 | Cards, rows, inputs |
| `surfaceRaised` | #222B57 | Selected rows, secondary buttons |
| `border` | #2E3870 | Outlines |
| `textPrimary` | #EEF0FA | Main text |
| `textSecondary` | #AEB5D6 | Supporting text |
| `accentCalm` | #9DB2FF | Selection, "dry · glide", progress |
| `accentWarm` | #F4BE8A | Primary action, "flaring · pat" |
| `onAccent` | #0E1430 | Text on accent fills |

All text pairs pass WCAG AA (4.5:1). Calm/warm accents differ in lightness, and
every state also has a text label, so color is never the only signal.

## Layout
- Spacing (`HBSpacing`): 4, 8, 12, 16, 24, 32, 48; screen gutter 22.
- Radius (`HBRadius`): 12, 16, 18, 24, continuous corners.
- Touch targets ≥ 44 pt; buttons 56 pt tall.
- Icons: SF Symbols via `HBIcon` only, so one idea = one icon.

## Components
`HBButtonStyle` (.hbPrimary / .hbSecondary / .hbGhost), `HBIconButton`,
`HBChip`, `HBStatusTile`, `HBRadioRow`, `HBCard`, `HBSectionHeader`,
`HBScreenHeader`, `HBNotice`, `HBBadge`, `HBSegmentedProgress`, `HBCatalogView`.
