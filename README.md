# Three Blind Mice

macOS menu bar utility that remaps mouse scroll and buttons to keyboard-style navigation actions.

## Project layout

| Path | Purpose |
|------|---------|
| `three-blind-mice-app/` | **The app** — open `ThreeBlindMice.xcodeproj` here |
| `linearmouse-main/` | Local reference only (not shipped; ignored by git) |
| `Mos-master/` | Local reference only (not shipped; ignored by git) |

## Build and run

See [three-blind-mice-app/README.md](three-blind-mice-app/README.md).

Open **`three-blind-mice-app/ThreeBlindMice.xcodeproj`** in Xcode, run the **Three Blind Mice** scheme, then grant **Accessibility** permission for **Three Blind Mice** in System Settings.

## Share a build with others

1. Xcode → **Product → Build** (Release recommended).
2. **Product → Show Build Folder in Finder** → `Products/Release/Three Blind Mice.app`
3. Zip the `.app` and send it.
4. Recipients: unzip, move to Applications, **right-click → Open** the first time, then enable Accessibility for the app.
