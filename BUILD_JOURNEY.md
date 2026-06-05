# Three Blind Mice — Build Journey

A record of how this macOS menu bar app was built through an AI-assisted chat session (May 27, 2026). This document focuses on **your prompts**, **product decisions**, **where things broke**, and **how you corrected course**.

**Repository:** [github.com/whizabz/three-blind-mice](https://github.com/whizabz/three-blind-mice)

---

## What you set out to build

A **fresh macOS menu bar utility** (inspired by LinearMouse and Mos, not a fork) that remaps **physical mouse input to keyboard-style navigation** for blind / screen-reader-oriented use — **without integrating with VoiceOver or any screen reader**. The app only synthesizes keyboard events (Tab, Enter, Space, etc.).

---

## Phase 1 — Discovery and product shape

### Prompt 1

> In this project folder I've Got code from two other open-source Mac OS apps that I have used in the past. Both of these apps enable users to modify aspects of a physical mouse by giving users the ability to modify what button clicks do, manage scroll preferences, and other things. They use Mac OS's accessibility settings to do this. Can you go through the code for both of these and just understand how things have been built? I want to create a similar app but for a very specific use case - enabling screen reader users to use a physical mouse to navigate the UI. My idea is to allow the scroll up and down to essentially work like Tab and Shift+Tab from the keyboard.And the left click to work like Enter or Space, right click to work more like a Shift Enter, something on those lines. Plus, the back and forward buttons on some mice can be customised to do other things. I still haven't thought through everything that this app should allow users to customise, because I'm not fully familiar with screen reader navigation keyboard shortcuts, but I want to work in that direction. Step one for me would be to figure out the basics of how these apps are doing things, and then try and figure out how I would implement it for the use case I'm thinking of. I have code-named the project "Three Blind Mice" right now. Can you help me plan this out?

**Outcome:** Architecture review of LinearMouse + Mos; implementation plan drafted.

### Prompt 2

> I want to use LinearMouse and Mos as an inspiration and to figure out how things are done to build a Mac OS app, which I've never done before. The app is not going to integrate with any screen reader technologies. All it's going to do is allow me to change things for my physical mouse so I can use the controls in the way I described. In practise, it will be very similar to how LinearMouse does things. It's got a settings UI, which allows me to customise buttons. There's a menu bar icon at the top, which I can use to open the settings or take quick actions. That's it.

**Decision:** Fresh app; LinearMouse-like shell; no screen reader integration.

### Prompt 3

> You've taken some of my examples for what the buttons do as the final implementation. I don't think I have that completely figured out. Here is some text which talks about how basic keyboard navigation works today. I think the app needs to provide the ability to map some of these things to mouse buttons. See if some of this needs to be included as part of the plan.
>
> Basic macOS Keyboard Navigation
>
> | Key | What it usually does |
> |-----|----------------------|
> | Tab | Move to next focusable item |
> | Shift + Tab | Move to previous focusable item |
> | Arrow Keys | Move within menus, lists, tables, radio groups, text |
> | Enter / Return | Open, confirm, submit, or activate |
> | Space | Toggle or directly activate controls |
> | Esc | Close, cancel, dismiss |
> | Cmd + Tab | Switch between apps |
> | Cmd + ` | Switch between windows of same app |
>
> *(Plus detailed notes on Tab, Shift+Tab, arrow keys, Enter vs Space semantics, Esc, etc.)*

**Decision:** Flexible mapping model with a **navigation action catalog**, not hardcoded scroll=Tab / click=Enter.

### Prompt 4

> I think we can just start with the minimal preset profile and provide the ability to configure things. Let's begin with just that.

**Outcome:** Domain models, minimal preset, JSON config, Swift package scaffold.

---

## Phase 2 — First runnable app in Xcode

### Prompts 5–7

> Yes, let's move ahead
>
> Ok, let's move ahead. When it is time, let me know when I shuold open xcode and try the app myself.
>
> Do you want to work on any other phase before I open it in xcode?

**Outcome:** Menu bar app shell, settings UI, permission flow built before first Xcode run.

### Prompt 8 — Xcode console noise

> I see the following messages when I press play in xcode:
> Unable to get synchronousRemoteObjectProxy, error: Error Domain=NSCocoaErrorDomain Code=4097 "connection to service named com.apple.linkd.autoShortcut" ...
> *(Many repeated lines)*
> Cannot index window tabs due to missing main bundle identifier

**Resolution:** Mostly harmless Xcode noise; separate issue was missing bundle ID for real Accessibility behavior.

### Prompt 9 — Remapping dead after permission

> I just granted permissions, but when I try to scroll after that, it does not have an effect. I have a web page open in the browser, which I would expect that if I scroll, it should start doing the tab and Shift+Tab. I also tried to disable and re-enable from the menu bar icon.

**Root cause:** SPM bare executable lacked bundle ID; event tap didn't restart after grant.

**Fix:** Xcode project with bundle ID; restart tap on permission refresh.

### Prompt 10

> When I try to open settings: Please use SettingsLink for opening the Settings scene

**Fix:** Custom `SettingsWindowController` (AppKit-hosted window) instead of SwiftUI `SettingsLink`.

### Prompt 11

> It keeps saying that I need to provide accessibility permissions. Maybe that's the part that didn't work.

**Fix:** Stale permission entries from `.build/` paths; enable **Three Blind Mice** only in System Settings.

### Prompts 12–13 — Wrong Xcode paths

> Wen I opened the xcodeproj and clicked
>
> When I opened the xcodeproj and clicked on the topmost thing in the Xcode file explorer, then press play. This is the error message I got.
> Build input files cannot be found: '/Users/abz/AI Playground/three-blind-mice/Sources/three-blind-mice-app/InputRemappingService.swift', ... Did you forget to declare these files as outputs of any script phases or custom build rules which produce them?

**Fix:** Corrected `project.pbxproj` source paths (later flattened to repo root).

### Milestone

> That worked like a charm!

Core remapping validated in browser (scroll → Tab / Shift+Tab).

---

## Phase 3 — Global toggle shortcut and sounds

### Prompt 14

> That worked like a charm! I think we need a universal keyboard shortcut so that I can enable and disable the remapping because once I enabled the mapping. I wasn't able to click on the menu bar icon to stop it. Can we set it by default to control-option-M, and have a place in settings where that can be overridden?
>
> And, we can move ahead from here.

**Shipped:** Default **⌃⌥M** toggle; configurable in settings.

### Prompt 15

> @/Users/abz/Downloads/On Beep freesound_community-beep-6-96243.mp3 @/Users/abz/Downloads/Off Beep freesound_community-short-beep-tone-47916.mp3 Can you add these sounds to indicate when the remapping is turned on and off?

**Shipped:** `remapping-on.mp3` / `remapping-off.mp3`.

### Prompt 16

> The keyboard shortcut doesn't seem to be working. Plus it's asking for accessibility permission again. The sounds are working fine.

**Fix:** Merged hotkey into single event tap (two taps conflicted).

### Prompt 17

> Everything seems to be working perfectly. We can move ahead

---

## Phase 4 — Settings UX and pointer lock (longest struggle)

### Prompt 18

> The settings UI is not scrollable - there are additional settings but I can't see them. Also, I should be able to navigate the settings using the keyboard seeing how I'm building an app for screen reader users.

### Prompt 19

> The scroll is there now, but I still can't navigate settings with the keyboard.
>
> Also, can you check if there is a way to disable pointer movement? When a blind user uses this application, the only thing relevant to them is the rest of the buttons. If the pointer moves and hovers over something unintended, I don't want that to happen.

**Shipped:** Pointer lock (freeze cursor while remapping).

**Not solved:** Settings keyboard Tab navigation.

### Prompt 20

> The remapping seems to be broken now, but I can see the rest of the changes. Also, the keyboard navigation is still not working for the settings.

### Prompt 21 — Key diagnosis from you

> OK, I know what is happening. As long as the app remains open, the remapping doesn't work. I have to close the app window every time for the remapping to work. I think we can drop the idea of turning off the mapping when the app is on. The mapping can continue to be controlled by the keyboard shortcut or the toggle. Also, I still cannot navigate the settings UI using my keyboard, using Tab and Shift+Tab to move around, am I doing something wrong? Do I need voiceover to be enabled for that to happen?

**Decision:** Remove remapping bypass while settings open.

**Clarification:** macOS **Keyboard Navigation** (system setting), not VoiceOver, for Tab in apps.

### Prompts 22–24

> Everything seems to be working fine except for the settings keyboard navigation. I have the Keyboard Navigation system setting on.
>
> Tab / Shift Tab is not doing anything in the settings UI. *(sent twice)*

### Failed approaches (assistant)

| Attempt | Result |
|--------|--------|
| `@FocusState` + `.onKeyPress` on wrapper | Focus ring on whole panel |
| Local Tab monitor returning `nil` | Tab swallowed, no movement |
| Settings-only scroll → synthetic Tab | Scroll dead in settings body |
| AppKit `selectKeyView` / focus controllers | Scroll + focus both broken |

### Prompts 25–27

> I can see the tab focus now rectangle, but it is only at the topmost level. It's not moving inside. And in whatever way it is focusing now, my scroll has also stopped working.
>
> Both the scroll and the focus are now completely broken.
>
> Still not working, scroll and keyboard focus

### Prompt 28 — Explicit rollback (your correction)

> It's not working, can you take things back to when the scroll was working, but there was no keyboard navigation?

**Outcome:** Reverted focus hacks; remapping stable again; settings keyboard nav **deferred**.

### Prompts 29–30 — You diagnosed scroll bug

> I just realised what is happening. The view is scrolling when my mouse pointer is on the scroll bar, but if it's inside the body of the UI, the scroll is not happening.
>
> The remapping is off, the scroll is still not working. I'm only able to scroll when the mouse pointer is in the scroll bar area

**Root causes:**

1. Event tap consumed scroll over settings content → fixed with pass-through when pointer is over settings window.
2. `NSScrollView` document view same height as viewport → fixed with SwiftUI `ScrollView`.

---

## Phase 5 — Settings window sizing

### Prompts 31–35

> I think the window is too large and there is no scroll.
>
> Didn't work - the window is still taller than the screen.
>
> This is not working. The window is still larger than the screen. Can you try another model to fix it?
>
> Can you make the settings window resizable?
>
> Something is wrong, the window is not resizable. Can you make sure that the default height is smaller than the screen height?

**Fixes:** Screen-clamped default frame; preserve user resize; removed intrinsic sizing that fought resize; smaller default height.

---

## Phase 6 — Icons, distribution, GitHub

### Prompts 36–41

> How can I add an app icon? I have an icon composer .icon file
>
> Figured it out. That's all set. Now if I want to use a different icon for the menu bar, what do I need to do?
>
> I want to use the sy symbol named eyeglasses, and I want it to have an outline state when the remapping is disabled, and a filled state when it is enabled
>
> Error: No symbol named 'eyeglasses.fill' found in system symbol set
>
> Can I give you you a custom SVG?
>
> For now, can you use sunglasses and sunglasses.fill?

**Shipped:** Menu bar **sunglasses** / **sunglasses.fill** (with fallback if `.fill` missing). App icon via Icon Composer (you set up yourself).

### Prompts 42–43 — Sharing builds

> Ok, can I share a .app file with friends for them to try it out?
>
> I don't think I'm able to follow the flow, do you want me to find a .app file in the finder somewhere?

**Guidance:** Release build → DerivedData `Products/Release` → zip → right-click Open → Accessibility permission.

### Prompts 44–48 — Repo cleanup

> Ok, now, can you cleanup the project folder and help me check relevant files into github?
>
> Here's the repo: https://github.com/whizabz/three-blind-mice.git And my username is whizabz@gmail.com
>
> I'm ok using just whizabz. Also in the repo I can see that there is a subfolder called "three-blind-mice-app". Should it be like that, or should all the project files live one level up?
>
> Yes, please flatten the repo
>
> /Users/abz/AI Playground/three-blind-mice has things other than what's in the repo, can you cleanup this folder so it matches the repo?

**Outcome:** Git init, push to GitHub, flattened layout, removed local reference clones from repo folder.

### Prompt 49 — Latest UI change

> The settings UI, instead of a long scroll, can you move the different sections into tabs?

**Shipped:** Tabs — General | Shortcut | Accessibility | Mappings.

---

## Progressive product decisions

| Topic | Started as | Landed as |
|-------|------------|-----------|
| Scope | Screen-reader-integrated nav | Synthetic keys only |
| Mappings | Example defaults | Minimal preset + full picker |
| Build | Swift Package | Xcode app (bundle ID) |
| Disable remapping | Menu bar only | **⌃⌥M** + menu + sounds |
| Settings window | SwiftUI Settings scene | AppKit-hosted window |
| Remapping while settings open | Paused (bug) | Always on unless toggled off |
| Pointer | Normal movement | **Lock position** (default on) |
| Settings keyboard Tab | Required for a11y audience | **Deferred** (unsolved) |
| Settings layout | Long scroll | **Tabs** |
| Menubar icon | Generic SF Symbol | **Sunglasses** outline/filled |
| Repo | Nested + reference code | Flat GitHub repo |

---

## Current app state (end of chat)

- Menu bar app with sunglasses icon (filled = remapping on)
- CGEvent tap: scroll/buttons → configured keyboard actions globally
- Toggle: ⌃⌥M (configurable), menu toggle, settings toggle
- Optional pointer lock while remapping
- Settings: four tabs (General, Shortcut, Accessibility, Mappings)
- Config: `~/Library/Application Support/three-blind-mice/config.json`
- Enable/disable sounds
- GitHub: [whizabz/three-blind-mice](https://github.com/whizabz/three-blind-mice)

---

## Known open gap

**Settings UI keyboard navigation (Tab / Shift+Tab between controls)** — multiple approaches failed without breaking scroll or remapping. Explicitly rolled back to prioritize working core remapping. Future work item.

---

## One-paragraph summary

I built **Three Blind Mice**, a macOS menu bar utility that uses Accessibility permissions and a global event tap to turn mouse scroll and buttons into keyboard actions for blind-friendly navigation—without hooking into VoiceOver. I used LinearMouse/Mos as reference only, started from a configurable minimal preset, hit real macOS pitfalls (bundle ID, event tap lifecycle, settings window hosting), added ⌃⌥M and pointer lock when the menu bar became unreachable, and spent a long iteration on settings UX (scroll, window size, tabs) while **deferring** settings keyboard focus after several broken attempts. The project is on GitHub with a flat Xcode layout and is shareable as a zipped Release `.app`.

---

## Appendix — Full keyboard navigation reference (Prompt 3)

> Basic macOS Keyboard Navigation
>
> Key | What it usually does
> Tab | Move to next focusable item
> Shift + Tab | Move to previous focusable item
> Arrow Keys | Move within menus, lists, tables, radio groups, text
> Enter / Return | Open, confirm, submit, or activate
> Space | Toggle or directly activate controls
> Esc | Close, cancel, dismiss
> Cmd + Tab | Switch between apps
> Cmd + ` | Switch between windows of same app
>
> Tab — Moves focus forward. Typical targets: Buttons, Links, Inputs, Dropdowns, Checkboxes.
>
> Shift + Tab — Moves focus backward.
>
> Arrow Keys — Behavior depends on context (text field, menu, radio group, table, dropdown, sliders).
>
> Enter / Return — Open, confirm, submit, activate. Think: "Proceed with this."
>
> Space — Toggle, select, immediate action. Think: "Change the current state."
>
> Enter vs Space — Distinction matters for accessibility (buttons, checkboxes, toggles, links, text inputs).
>
> Esc — Close modal, dismiss menu, exit fullscreen, cancel.

---

## Appendix — All user prompts (numbered)

1. In this project folder I've Got code from two other open-source Mac OS apps... Can you help me plan this out?
2. I want to use LinearMouse and Mos as an inspiration... menu bar icon... settings UI... That's it.
3. You've taken some of my examples as final implementation... *(keyboard navigation reference — see appendix above)*
4. I think we can just start with the minimal preset profile and provide the ability to configure things. Let's begin with just that.
5. Yes, let's move ahead
6. Ok, let's move ahead. When it is time, let me know when I shuold open xcode and try the app myself.
7. Do you want to work on any other phase before I open it in xcode?
8. I see the following messages when I press play in xcode: *(linkd.autoShortcut errors; missing main bundle identifier)*
9. I just granted permissions, but when I try to scroll after that, it does not have an effect...
10. When I try to open settings: Please use SettingsLink for opening the Settings scene
11. It keeps saying that I need to provide accessibility permissions. Maybe that's the part that didn't work.
12. Wen I opened the xcodeproj and clicked
13. When I opened the xcodeproj... Build input files cannot be found: '.../Sources/three-blind-mice-app/...'
14. That worked like a charm! ... universal keyboard shortcut ... control-option-M ... settings where that can be overridden
15. Can you add these sounds ... remapping turned on and off?
16. The keyboard shortcut doesn't seem to be working. Plus it's asking for accessibility permission again. The sounds are working fine.
17. Everything seems to be working perfectly. We can move ahead
18. The settings UI is not scrollable ... navigate the settings using the keyboard
19. The scroll is there now, but I still can't navigate settings with the keyboard. Also ... disable pointer movement?
20. The remapping seems to be broken now ... keyboard navigation is still not working for the settings.
21. As long as the app remains open, the remapping doesn't work ... drop turning off mapping when settings is on ... Do I need voiceover?
22. Everything seems to be working fine except for the settings keyboard navigation. I have the Keyboard Navigation system setting on.
23. Tab / Shift Tab is not doing anything in the settings UI.
24. Tab / Shift Tab is not doing anything in the settings UI.
25. I can see the tab focus now rectangle, but it is only at the topmost level ... scroll has also stopped working.
26. Both the scroll and the focus are now completely broken.
27. Still not working, scroll and keyboard focus
28. It's not working, can you take things back to when the scroll was working, but there was no keyboard navigation?
29. The view is scrolling when my mouse pointer is on the scroll bar, but if it's inside the body of the UI, the scroll is not happening.
30. The remapping is off, the scroll is still not working. I'm only able to scroll when the mouse pointer is in the scroll bar area
31. I think the window is too large and there is no scroll.
32. Didn't work - the window is still taller than the screen.
33. This is not working. The window is still larger than the screen. Can you try another model to fix it?
34. Can you make the settings window resizable?
35. Something is wrong, the window is not resizable. Can you make sure that the default height is smaller than the screen height?
36. How can I add an app icon? I have an icon composer .icon file
37. Figured it out. That's all set. Now if I want to use a different icon for the menu bar, what do I need to do?
38. I want to use the sy symbol named eyeglasses ... outline when disabled, filled when enabled
39. Error: No symbol named 'eyeglasses.fill' found in system symbol set
40. Can I give you you a custom SVG?
41. For now, can you use sunglasses and sunglasses.fill?
42. Ok, can I share a .app file with friends for them to try it out?
43. I don't think I'm able to follow the flow, do you want me to find a .app file in the finder somewhere?
44. Ok, now, can you cleanup the project folder and help me check relevant files into github?
45. Here's the repo: https://github.com/whizabz/three-blind-mice.git And my username is whizabz@gmail.com
46. I'm ok using just whizabz. Also ... should all the project files live one level up?
47. Yes, please flatten the repo
48. /Users/abz/AI Playground/three-blind-mice has things other than what's in the repo, can you cleanup this folder so it matches the repo?
49. The settings UI, instead of a long scroll, can you move the different sections into tabs?
50. I want to explain to someone what all have I done in this chat...
51. I like this. Can you give me an MD file for this? ... include the full versions of truncated prompts
