# UI Interaction Animation Design

## Goal

Add a shared hover and click interaction system across the floating island, menu bar content, and settings UI so the app feels more alive without changing the underlying Codex business state model.

## Scope

- Add a shared interaction layer for `resting`, `hovered`, and `pressed`.
- Keep existing Codex states (`idle`, `running`, `success`, `error`) as the primary business state input.
- Apply the strongest interaction treatment to the floating island.
- Apply the same visual language, with lower intensity, to menu bar and settings surfaces.
- Keep `animationsEnabled` as the existing user-facing kill switch for non-essential motion.

## Architecture

### Business State vs Interaction State

The app already has a clear business state source in `CodexStatusService`. The new UI behavior should not extend or overload `CodexState`. Instead, each interactive surface will combine:

- `CodexState` for semantic status-driven visuals
- `InteractivePhase` for pointer-driven feedback

This separation keeps hover and pressed behavior local to the UI and prevents window, service, or provider logic from needing to understand pointer events.

### Shared Interaction Layer

Add a `UI/Interaction` area that contains:

- `InteractivePhase`
- shared interaction tokens/configuration
- a reusable surface modifier for panels/cards/capsules
- a reusable button style for pointer-aware actions

This keeps animation parameters centralized and avoids scattering `onHover`, scale values, and shadow values across multiple SwiftUI views.

### Lobster-Specific Overlay Behavior

`LobsterAvatarView` already renders per-state animation frames. Extend it so interaction phase can amplify or bias the existing animation instead of replacing it. Hover should feel like the mascot is responding to attention; press should feel like a short, reactive burst.

## UI Behavior

### Floating Island

- Root island gets pointer-aware hover and press treatment.
- Hover: slight lift, mild scale-up, edge highlight, accent glow, and more energetic lobster response.
- Press: short compression and rebound, with the lobster reacting in sync.
- Expanded/compact transitions remain click-driven only; hover should not auto-expand.

### Menu Bar Content

- Keep the same interaction language but reduce motion intensity.
- Primary action rows and buttons should feel responsive rather than fully custom-skinned.
- Toggles and menus can inherit subtle hover surfaces even when using native controls.

### Settings

- Replace purely static grouped presentation with card-like section surfaces where helpful.
- Preview area should visibly react to hover.
- Buttons and state chips should use the shared button style.
- Settings controls should keep readability first; motion stays lighter than the island.

## Accessibility and Fallback

- When `animationsEnabled` is disabled, preserve minimal state feedback (highlight, subtle scale or opacity) and remove the more expressive motion.
- Avoid any interaction that hides information, auto-expands views, or steals focus.

## Testing Strategy

- Add a package test target.
- Test the interaction token mapping so phase-driven values stay stable.
- Test reduced-motion fallback for shared interaction configuration.
- Keep UI integration verification at build/runtime level rather than snapshot-heavy tests.
