# Food Ninja Light Design System

## Design Authority

The Customer and Admin interfaces follow the visual language of the Pixel True Food Ninja Figma kit. The project implements **light mode only**. Dark-mode frames in the kit are reference material and must not be implemented.

Design reference:

- Figma file: `Pixel True - Food Delivery UI Kit`
- Local source: `C:/Users/pc/Downloads/Free Food Delivery UI Kit/Free Food Delivery UI Kit/Pixel True - Food Delivery UI Kit.fig`
- Primary Figma gradient: `#53E88B -> #15BE77`
- Primary application typeface: `Poppins`

The Figma kit controls visual direction. This document controls reusable implementation tokens. When a frame and this document differ, preserve the frame's composition and update this document deliberately if the difference should become a project-wide rule.

## Light Mode Only

- `MaterialApp` must use `themeMode: ThemeMode.light`.
- Provide one `ThemeData` named `AppTheme.light` or equivalent.
- Do not create `darkTheme`, dark token files, a theme switch, or a dark-mode settings row.
- Do not follow the dark frames supplied in Food Ninja.
- SharedPreferences must not persist a light/dark choice. It may still persist onboarding, language, and notification preference hints.
- Use a transparent or white system status bar with `Brightness.dark` icons.
- All screens, dialogs, bottom sheets, snackbars, loading states, empty states, and notification surfaces must remain readable in the light palette.

## Color Tokens

All application colors must be defined once in `lib/core/theme/app_colors.dart`. Widgets must reference semantic tokens and must not repeat hexadecimal literals.

### Brand Colors Extracted from Figma

| Token | Value | Usage |
|---|---|---|
| `primaryStart` | `#53E88B` | Start of the Food Ninja green gradient |
| `primaryEnd` | `#15BE77` | End of the Food Ninja green gradient and strong green accent |
| `primarySolid` | `#21C67B` | Solid active icon, link, compact control, focus accent |
| `primarySoft` | `#E1F6F4` | Selected/filter background, soft highlight |
| `primaryTint` | `#4EE489` at 10% | Subtle green surface tint |
| `info` | `#25A0B0` | Informational state when a blue-green accent is needed |

### Neutral Colors Extracted from Figma

| Token | Value | Usage |
|---|---|---|
| `background` | `#FFFFFF` | Main scaffold background |
| `surface` | `#FFFFFF` | Cards, dialogs, sheets and navigation surfaces |
| `textPrimary` | `#09051C` | Page titles, item names, totals and primary content |
| `textSecondary` | `#444352` | Descriptions and secondary labels |
| `textMuted` | `#86848F` | Hints, metadata and disabled text |
| `border` | `#CECDD2` | Dividers and visible input borders |
| `surfaceMuted` | `#F6F6F6` | Disabled controls and low-emphasis grouped surfaces |

### Food and Warm Accent Scale Extracted from Figma

| Token | Value | Usage |
|---|---|---|
| `warning` | `#FFAD1D` | Warning state, pending status and rating star |
| `warningMedium` | `#FFC668` | Warning chip background accent |
| `warningSoft` | `#FFDEA4` | Soft warning surface |
| `warningSurface` | `#FEF8E0` | Very light warning background |
| `foodAccentDark` | `#DA6317` | Food illustration/accent only |
| `foodAccent` | `#E38751` | Food illustration/accent only |
| `foodAccentSoft` | `#E6A986` | Food illustration/accent only |
| `foodAccentMuted` | `#E3CBBC` | Food illustration/accent only |

### Application Semantic Additions

These colors support states required by the ordering product. They must remain semantic and must not replace the green brand palette.

| Token | Value | Usage |
|---|---|---|
| `error` | `#FF4B4B` | Validation, rejection, cancellation and destructive action |
| `errorSoft` | `#FFF0F0` | Error chip/background |
| `success` | `#15BE77` | Completed and successful state |
| `successSoft` | `#E8F9F0` | Success chip/background |
| `scrim` | `#09051C` at 45% | Modal backdrop only |

Do not use the primary gradient for error, cancellation, rejection, or destructive buttons. Use `error` with an explicit label and confirmation step.

## Gradients

The main Food Ninja gradient is:

```dart
const LinearGradient appPrimaryGradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [Color(0xFF53E88B), Color(0xFF15BE77)],
);
```

Use it for primary call-to-action buttons, selected high-emphasis states, the logo treatment, and small decorative accents. Do not apply it to large content backgrounds, body text, entire cards, or every icon.

## Typography

Use **Poppins** for all application text. The Sora font found on the promotional Start Here page is not part of the in-app type system. Preserve logo lettering as an exported vector asset instead of recreating it with a second font.

Bundle the required Poppins font files under `assets/fonts/` and declare them in `pubspec.yaml`. Do not depend on a network request for the primary font.

| Text style | Size | Weight | Line height | Typical usage |
|---|---:|---:|---:|---|
| `displayLarge` | 32 | 700 | 40 | Onboarding hero only |
| `headlineLarge` | 25 | 700 | 33 | Main page title |
| `headlineMedium` | 22 | 700 | 30 | Major section or total |
| `titleLarge` | 18 | 600 | 26 | Card/detail title |
| `titleMedium` | 16 | 600 | 24 | List item title and dialog title |
| `bodyLarge` | 16 | 400 | 24 | Main readable body copy |
| `bodyMedium` | 14 | 400 | 21 | Default labels and descriptions |
| `labelLarge` | 14 | 600 | 20 | Buttons and emphasized controls |
| `bodySmall` | 12 | 400 | 18 | Metadata and helper text |
| `labelSmall` | 11 | 500 | 16 | Compact chips and navigation labels |

Rules:

- Use at most three type styles on a normal screen.
- Use `textPrimary` for headings, `textSecondary` for body content, and `textMuted` for hints.
- Do not use font weights below 400 for readable application copy.
- Buttons use Poppins 14 or 16, weight 600, with no forced uppercase.
- Prices and order totals use weight 700 and tabular figures where available.

## Spacing and Layout

Use a 4-point grid. Allowed general spacing tokens are `4, 8, 12, 16, 20, 24, 32, 40` logical pixels.

- Screen horizontal padding: `24` on standard phones; may reduce to `16` below 360 logical pixels.
- Top-level section gap: `24` or `32`.
- Card internal padding: `16`.
- List item gap: `12` or `16`.
- Icon-to-label gap: `8`.
- Form field vertical gap: `16`.
- Primary bottom action clearance: at least `24` plus `SafeArea` inset.
- Reference frame widths: 375-390 logical pixels. Use responsive constraints rather than fixed screen coordinates.

Use `SafeArea`, `LayoutBuilder`, flexible constraints, and scrollable form content. A screen must not overflow at 320 logical pixels wide or with text scale 1.3.

## Shape and Radius

| Token | Value | Usage |
|---|---:|---|
| `radiusSmall` | 8 | Chips, small images, counters |
| `radiusMedium` | 12 | Compact cards and status containers |
| `radiusInput` | 15 | Text fields and search fields |
| `radiusCard` | 16 | Standard cards and list tiles |
| `radiusLarge` | 20 | Large image cards and bottom sheets |
| `radiusDialog` | 24 | Dialogs and large modal surfaces |
| `radiusPill` | 999 | Pills, status chips and circular-ended controls |

Avoid mixing arbitrary radii. Circular controls use `BoxShape.circle`.

## Elevation and Shadows

Food Ninja uses soft, colored shadows. Shadows must remain subtle in the light theme.

```dart
const cardShadow = BoxShadow(
  color: Color(0x0D09051C),
  offset: Offset(0, 4),
  blurRadius: 20,
);

const primaryShadow = BoxShadow(
  color: Color(0x2E53E88B),
  offset: Offset(0, 8),
  blurRadius: 20,
);
```

- Use `cardShadow` on floating cards, search fields, and navigation surfaces.
- Use `primaryShadow` only for the main primary action or selected promotional card.
- Do not stack multiple heavy shadows.
- Use a border instead of a shadow inside dense Admin lists.

The large promotional mockup shadows present in the Start Here page are not copied directly to mobile components because their scale is intended for presentation artwork.

## Core Components

### Primary Button

- Height: `56`.
- Horizontal padding: `24`.
- Radius: `15`.
- Fill: `appPrimaryGradient`.
- Label: white, Poppins 14-16, weight 600.
- Disabled: `surfaceMuted` fill with `textMuted` label and no shadow.
- Loading: keep the same width and show a centered white progress indicator.

### Secondary Button

- Height: `52-56`.
- White surface, green label, and a one-pixel `primaryEnd` border.
- Destructive secondary actions use `error`, not green.

### Text Field and Search Field

- Minimum height: `56`.
- Radius: `15`.
- Fill: white.
- Default border: transparent or `border` at low emphasis.
- Focus border: `primaryEnd`, 1.5-2 pixels.
- Error border/text: `error`.
- Prefix and suffix icons: 20-24 logical pixels.
- Never indicate error by color alone; include helper text.

### Cards

- White surface, radius `16`, internal padding `16`.
- Food image radius `12-16`.
- Use one light shadow or border, not both unless the Figma frame clearly requires it.
- Keep name, price, availability, and action order consistent across Home, Search, Favorites, and Admin menu lists.

### Status Chips

- `Pending`: warning text on `warningSurface`.
- `Confirmed` and `Preparing`: green text on `primarySoft`.
- `OutForDelivery`: info text on a pale info background.
- `Completed`: success text on `successSoft`.
- `Cancelled` and `Rejected`: error text on `errorSoft`.
- Chip text must remain readable without relying on hue alone.

### Navigation

- Bottom navigation surface: white with a very soft shadow.
- Active icon and label: `primaryEnd` or the green gradient when supported cleanly.
- Inactive icon and label: `textMuted`.
- App bars normally use white/transparent backgrounds, dark icons, and no default Material elevation.

## Imagery and Icons

- Export logos and simple icons from Figma as SVG.
- Export food photography and complex raster artwork as PNG or WebP at suitable density.
- Do not export full screens, buttons, fields, or cards as images.
- Use one icon family consistently; prefer the kit's exported icons, otherwise use Material Symbols Rounded.
- Standard icon sizes are 20, 24, and 28 logical pixels.
- Provide semantic labels for actionable icons and alt descriptions where applicable.

## Motion

- Standard duration: `180-250 ms`.
- Page/large state transition: up to `300 ms`.
- Use ease-out for entry and ease-in for exit.
- Motion supports feedback and hierarchy; it must not delay ordering actions.
- Respect reduced-motion platform settings where available.

## Flutter Theme Files

Implement the system through these shared files:

```text
lib/core/theme/
├── app_colors.dart
├── app_gradients.dart
├── app_radii.dart
├── app_shadows.dart
├── app_spacing.dart
├── app_text_styles.dart
└── app_theme.dart
```

Shared UI components belong under `lib/core/widgets/`. Feature screens must not create their own competing token sets.

## Review Checklist

- The app has one light theme and no dark-mode toggle or token branch.
- No feature widget contains repeated hard-coded brand colors, radii, text styles, or shadows.
- Poppins is used for all in-app text and the logo remains an asset.
- Primary actions use the green gradient consistently.
- Every screen uses the standard horizontal padding and spacing scale.
- Loading, empty, error, disabled, focused, selected, and success states use the same tokens.
- Customer and Admin screens look like one product.
- The screen is checked at common Android widths and text scale 1.3.
- Exported assets are individual SVG/PNG/WebP resources, not flattened UI screenshots.

## Attribution

Keep Pixel True attribution in the repository README or an About/Credits screen according to the UI kit's distribution terms. Do not present the original Food Ninja artwork as an independently authored design system.
