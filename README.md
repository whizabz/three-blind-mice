# Three Blind Mice

macOS menu bar utility that remaps mouse scroll and buttons to keyboard-style navigation actions.

## Build and run (Xcode)

Accessibility permission only works reliably when the app has a **bundle identifier**.

1. Open **`ThreeBlindMice.xcodeproj`** in this repo (not `Package.swift` alone).
2. Select scheme **Three Blind Mice**.
3. Press **Run**.
4. In **System Settings → Privacy & Security → Accessibility**, enable **Three Blind Mice**.
5. **Quit** the app completely (menu bar → Quit), then run again from Xcode.
6. The menu bar icon should reflect enabled/disabled state (sunglasses).

If you previously enabled a different entry (e.g. `three-blind-mice-app` or a path under `.build/`), remove those stale entries and enable **Three Blind Mice** only.

## Swift Package (development only)

`swift run` builds a bare executable without a bundle ID. macOS often will not apply Accessibility permission correctly. Use the Xcode project above for testing remapping.

## Share a build with others

1. **Product → Build** (use **Release** for sharing).
2. **Product → Show Build Folder in Finder** → open `Products/Release`.
3. Zip **`Three Blind Mice.app`** and send the zip.
4. Recipients: unzip, move to Applications, **right-click → Open** once, then grant Accessibility for **Three Blind Mice**.
