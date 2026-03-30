{\rtf1\ansi\ansicpg936\cocoartf2867
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\paperw11900\paperh16840\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 # Codex Lobster Island \'97 AGENTS.md\
\
## Mission\
Build a macOS-native app called **Codex Lobster Island**.\
\
This app is a **macOS top floating status island + menu bar utility** for visualizing Codex work status.\
It is **not** an iPhone Dynamic Island implementation.\
It should feel like a Mac-native \'93dynamic status island\'94 experience.\
\
The app must be:\
- macOS native\
- SwiftUI-first\
- AppKit-assisted where needed\
- structured for long-term maintainability\
- able to run as an MVP with mock data first\
- prepared for future integration with real Codex status sources\
\
---\
\
## Product Goal\
Create a small macOS utility that shows Codex status using:\
- a **top floating island window**\
- a **menu bar extra**\
- a **pixel / mosaic lobster mascot**\
- different animations and sounds for different statuses\
\
Primary statuses:\
- idle\
- running\
- success\
- error\
\
Future statuses should be easy to add later.\
\
---\
\
## Delivery Mode\
You must work in **continuous execution mode**.\
\
Rules:\
1. Do not stop after every small step to ask for permission.\
2. Continue phase by phase until the MVP is runnable.\
3. Only stop and ask if there is a true blocker that prevents implementation.\
4. Prefer making a reasonable engineering decision over asking unnecessary clarification questions.\
5. After each milestone, summarize what was completed and continue.\
\
When in doubt:\
- make the safest reversible decision\
- prefer maintainability\
- prefer MVP completion over over-engineering\
\
---\
\
## Execution Order\
Always follow this sequence:\
\
### Phase 1 \'97 Project skeleton\
- create folder structure\
- create domain models\
- create service layer skeleton\
- create app bootstrap\
- create menu bar entry\
\
### Phase 2 \'97 Floating island\
- implement top floating island window manager\
- compact island view\
- expanded island view\
- smooth show/hide behavior\
- no focus stealing\
\
### Phase 3 \'97 State system\
- implement status service\
- connect state to UI\
- mock state generator\
- state transitions for idle/running/success/error\
\
### Phase 4 \'97 Lobster UI\
- create lobster avatar component\
- placeholder art or procedural placeholder if final assets do not exist\
- unique animation behavior per state\
\
### Phase 5 \'97 Sound and settings\
- sound manager\
- mute toggle\
- startup at login setting\
- animation enable/disable\
- show/hide island setting\
\
### Phase 6 \'97 MVP polish\
- recent task detail\
- updated timestamps\
- settings panel\
- basic state history\
- cleanup and refactor\
\
### Phase 7 \'97 Future integration preparation\
- abstract Codex status provider protocol\
- prepare mock provider vs real provider architecture\
- do not bind to a fragile private implementation\
\
---\
\
## Output Style\
Whenever you complete a chunk of work, report in this format:\
\
### Completed\
- files added\
- files changed\
- what now works\
\
### Decisions\
- important architecture decisions\
- assumptions made\
\
### Next\
- what you are doing immediately after this\
\
Then continue implementation automatically.\
\
Do not repeatedly ask \'93continue?\'94 after each step.\
\
---\
\
## Engineering Constraints\
\
### Required stack\
- Swift\
- SwiftUI\
- AppKit when necessary\
- MenuBarExtra\
- NSWindow or NSPanel for floating island\
- UserDefaults for local settings\
- AVFoundation or NSSound for audio\
\
### Forbidden stack\
- Electron\
- Tauri\
- Flutter\
- React Native\
- web wrapper approach\
- giant monolithic single-file implementation\
\
### Quality bar\
- compileable\
- clear separation of concerns\
- minimal but clean UI\
- good naming\
- small focused files\
- easy future replacement of art/sound assets\
\
---\
\
## Architecture Rules\
\
Use clear layers:\
\
- App\
- Domain\
- Services\
- UI\
- Resources\
- Helpers\
\
Suggested models:\
- CodexState\
- CodexTask\
- AppSettings\
\
Suggested services:\
- CodexStatusService\
- MockStatusGenerator\
- FloatingIslandWindowManager\
- SoundManager\
- SettingsStore\
- LaunchAtLoginManager\
\
Suggested UI areas:\
- MenuBar\
- Island\
- Settings\
- Shared\
\
Keep window management logic out of view files whenever possible.\
\
---\
\
## Product Behavior Rules\
\
### Top island\
- appears near the top center of the active screen\
- visually compact in collapsed state\
- expands on click\
- should not aggressively interrupt the user\
- should not steal keyboard focus unnecessarily\
- should feel lightweight\
\
### Menu bar\
Must provide:\
- current state\
- toggle island visibility\
- mute toggle\
- settings entry\
- quit entry\
\
### States\
Implement exactly these first:\
- idle\
- running\
- success\
- error\
\
Suggested behavior:\
- idle: calm breathing\
- running: active looping motion\
- success: short celebration\
- error: warning / shake\
\
### Sound\
Support:\
- global mute\
- completion sound\
- error sound\
- optional running-start sound later\
\
---\
\
## UX Priorities\
Order of importance:\
1. runnable MVP\
2. correct architecture\
3. smooth state changes\
4. believable native macOS feel\
5. pretty visuals\
\
Do not overbuild early.\
Do not block progress waiting for perfect art assets.\
\
---\
\
## Asset Strategy\
If final lobster assets are unavailable:\
- create placeholder resources\
- keep resource paths stable\
- make it easy to swap assets later\
\
Do not hardcode asset assumptions all over the codebase.\
\
---\
\
## Real Codex Integration Strategy\
Prepare for a future provider-based design.\
\
Define an abstraction such as:\
- CodexStatusProviding\
\
Potential future providers:\
- MockCodexProvider\
- ProcessWatchingCodexProvider\
- LogParsingCodexProvider\
- SocketEventCodexProvider\
\
Do not bind the first MVP to brittle internal implementation details.\
\
---\
\
## Refactoring Rule\
If code starts getting coupled:\
- refactor before adding more surface area\
- keep the architecture clean\
\
---\
\
## Completion Rule\
Do not stop at scaffolding only.\
Do not stop at static UI only.\
Do not stop at pseudocode only.\
\
Keep going until there is a **runnable MVP** with:\
- menu bar entry\
- floating island\
- mock states\
- visible state changes\
- lobster placeholder animation\
- basic sound/settings behavior\
\
---\
\
## Final Handoff Requirement\
Before considering the MVP complete, provide:\
1. final project tree\
2. how to run locally\
3. what is implemented\
4. what is mocked\
5. how real Codex integration should be connected next}