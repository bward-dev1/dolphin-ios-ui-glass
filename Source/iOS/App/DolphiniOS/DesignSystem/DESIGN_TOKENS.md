# DolphiniOS Design Tokens — Tier 3 copy

Canonical copy lives in **`dolphin-ios-ui`** (Tier 1 "classic"), at this same
relative path. This file is a hand-ported copy for **Tier 3 "glass"**
(`dolphin-ios-ui-glass`, iOS 26+, native SwiftUI + Liquid Glass). If the
canonical spec changes, port the change here too.

Values are identical to Tier 1/Tier 2's; only the implementation idiom
differs. Unlike Tier 1 (hand-rolled `UIVisualEffectView` blur) and Tier 2
(SwiftUI `.ultraThinMaterial`), Tier 3 uses the **real** iOS 26 Liquid Glass
APIs (`.glassEffect(_:in:)`, `GlassEffectContainer`) — this is the showcase
tier, no simulation involved.

## Brand anchor

Anchored on the existing Liquid-Glass app icon work's gradient:
`#3217ff → #2b38ff → #2455ff → #1d74ff → #1792ff` ("Dolphin Blue").

## Color roles

Same values as Tier 1/2 — see `DesignTokens.json`. Under real Liquid Glass,
`color.surface.glass` is no longer a manually-tinted overlay — it's the
`Glass` shape style's own tint parameter, so treat the light/dark opacity
values here as a *starting point* to hand-tune once the effect is visible,
not a literal recipe like Tier 1/2's.

## Spacing / Radii / Type / Motion / Haptics

Identical values and intent to Tier 1/2 — see `DesignTokens.json`. Motion
should prefer `GlassEffectContainer`'s built-in morphing transitions between
glass shapes where applicable, rather than hand-rolled spring animations, to
get the real system-native glass-to-glass morph.

## Native Liquid Glass usage (Tier 3 only, no Tier 1/2 equivalent)

- Use `.glassEffect(.regular, in: RoundedRectangle(cornerRadius:))` (or
  `.clear` variant where content needs to stay fully legible through the
  glass) instead of any hand-rolled blur/material simulation.
- Group multiple glass elements that morph/interact together (e.g. a
  toolbar's buttons) inside a single `GlassEffectContainer` — this is what
  gives the real "liquid" morphing behavior between elements, which no
  amount of manual blur layering in Tier 1/2 can replicate.
- Tab bars/toolbars should adopt the system's native glass chrome
  automatically under iOS 26 when using stock `TabView`/`NavigationStack`
  APIs — don't fight the system style with custom backgrounds unless a
  screen genuinely needs a custom glass card (e.g. the onboarding hero).
- **Toolchain requirement**: `.glassEffect()`/`GlassEffectContainer` need
  the iOS 26 SDK at the *build* level, not just the deployment target. If
  CI's Xcode doesn't ship an iOS 26 SDK, these APIs won't compile at all —
  confirmed via a CI build before any real screen work starts (see repo
  history around the deployment-target-bump commit for the result).
