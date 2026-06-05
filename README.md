# Three Blind Mice

macOS menu bar utility that remaps mouse scroll and buttons to keyboard-style navigation actions.

## Build and run (Xcode)

Accessibility permission only works reliably when the app has a **bundle identifier** and is signed with a **Development Team** (free Apple ID works).

1. Open **`ThreeBlindMice.xcodeproj`** in this repo (not `Package.swift` alone).
2. **One-time setup:** copy `App/DevelopmentTeam.xcconfig.example` to `App/DevelopmentTeam.xcconfig` and replace `XXXXXXXXXX` with your Team ID from **Xcode → Three Blind Mice target → Signing & Capabilities → Team** (the 10-character ID in parentheses). Without this, macOS resets Accessibility permission after every rebuild because ad hoc signatures change each time.
3. Select scheme **Three Blind Mice**.
4. Press **Run**.
5. In **System Settings → Privacy & Security → Accessibility**, enable **Three Blind Mice**.
6. Rebuilds should keep permission once signing shows **Apple Development** on the Accessibility tab in settings.

If you previously enabled a different entry (e.g. `three-blind-mice-app` or a path under `.build/`), remove those stale entries and enable **Three Blind Mice** only.

## Swift Package (development only)

`swift run` builds a bare executable without a bundle ID. macOS often will not apply Accessibility permission correctly. Use the Xcode project above for testing remapping.

## Share a build with others

1. **Product → Build** (use **Release** for sharing).
2. **Product → Show Build Folder in Finder** → open `Products/Release`.
3. Zip **`Three Blind Mice.app`** and send the zip.
4. Recipients: unzip, move to Applications, **right-click → Open** once, then grant Accessibility for **Three Blind Mice**.
