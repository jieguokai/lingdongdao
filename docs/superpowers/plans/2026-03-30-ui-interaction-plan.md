# UI Interaction Animation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a shared hover and click interaction system across the floating island, menu bar content, and settings UI without changing the Codex business state architecture.

**Architecture:** Introduce a focused `UI/Interaction` layer that owns pointer phases, shared motion tokens, and reusable surface/button behavior. Apply the interaction system first in testable pure types, then wire it into island, menu bar, settings, and lobster rendering with reduced-motion fallback via the existing settings store.

**Tech Stack:** Swift 6.1, SwiftUI, Observation, Swift Package Manager, XCTest

---

### Task 1: Add a test target and lock interaction tokens with TDD

**Files:**
- Modify: `Package.swift`
- Create: `Tests/CodexLobsterIslandTests/InteractionStyleTests.swift`
- Create: `Sources/CodexLobsterIsland/UI/Interaction/InteractivePhase.swift`
- Create: `Sources/CodexLobsterIsland/UI/Interaction/InteractionStyle.swift`

- [ ] **Step 1: Write the failing test**
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Write minimal implementation**
- [ ] **Step 4: Run test to verify it passes**

### Task 2: Build reusable interaction surfaces

**Files:**
- Create: `Sources/CodexLobsterIsland/UI/Interaction/InteractiveSurfaceModifier.swift`
- Create: `Sources/CodexLobsterIsland/UI/Interaction/InteractiveButtonStyle.swift`
- Modify: `Sources/CodexLobsterIsland/UI/Island/IslandStyle.swift`

- [ ] **Step 1: Add pointer-aware surface and button primitives**
- [ ] **Step 2: Keep animation values sourced from shared interaction tokens**
- [ ] **Step 3: Build and verify there are no compiler errors**

### Task 3: Apply interaction system to floating island and lobster

**Files:**
- Modify: `Sources/CodexLobsterIsland/UI/Island/FloatingIslandRootView.swift`
- Modify: `Sources/CodexLobsterIsland/UI/Island/CompactIslandView.swift`
- Modify: `Sources/CodexLobsterIsland/UI/Island/ExpandedIslandView.swift`
- Modify: `Sources/CodexLobsterIsland/UI/Shared/LobsterAvatarView.swift`

- [ ] **Step 1: Add root hover behavior to the island**
- [ ] **Step 2: Convert compact island tap target to a shared interactive button**
- [ ] **Step 3: Feed interaction phase into lobster rendering**
- [ ] **Step 4: Build and visually verify expanded/compact transitions still work**

### Task 4: Apply interaction system to menu bar and settings

**Files:**
- Modify: `Sources/CodexLobsterIsland/UI/MenuBar/MenuBarStatusView.swift`
- Modify: `Sources/CodexLobsterIsland/UI/Settings/SettingsView.swift`

- [ ] **Step 1: Add shared interaction styling to menu bar actions and content blocks**
- [ ] **Step 2: Restructure settings surfaces where needed for hoverable cards**
- [ ] **Step 3: Build and verify controls remain readable and functional**

### Task 5: Final verification

**Files:**
- Modify as needed from prior tasks

- [ ] **Step 1: Run `swift test`**
- [ ] **Step 2: Run `swift build`**
- [ ] **Step 3: Fix any compiler or test failures**
- [ ] **Step 4: Summarize implemented behavior and remaining mock/reduced-motion limits**
