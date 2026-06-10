---
name: baguette
description: "Use Baguette for headless iOS 26 simulators: boot, view, drive, gesture, screenshot, smoke test, and integration-test Swift/SwiftUI/Xcode/Expo apps."
---

# Baguette

## Overview

Baguette is a host-side controller for iOS 26 simulators. Use it to replace the visible Simulator.app control surface during development and to drive integration smoke tests with CLI gestures and screenshots.

It still runs apps inside CoreSimulator. It is not a replacement for the simulator runtime, XCTest, Swift Testing, StoreKit tests, or real-device validation.

## Preflight

Check tool availability before using it:

```bash
xcodebuild -version
command -v baguette || brew install tddworks/tap/baguette
baguette --help
```

Requirements:

- Apple Silicon.
- Xcode 26+ selected with `xcode-select`.
- A simulator runtime compatible with the app.
- Baguette links private SimulatorKit/CoreSimulator frameworks, so failures can track Xcode updates.

## Live Development

Use this when the user wants a live simulator view without opening Simulator.app.

```bash
baguette serve
open http://localhost:8421/simulators
open http://localhost:8421/farm
```

Then:

1. Boot a simulator from the web UI, or use `baguette boot --udid <UDID>`.
2. Build/install/launch the app using the repo's normal Xcode commands, `xcrun simctl`, or the iOS debugger tools already used by the project.
3. Use the browser stream for visual inspection and gestures.
4. Use `/farm` when checking multiple booted devices at once.

Baguette CLI essentials:

```bash
baguette list --json
baguette boot --udid <UDID>
baguette shutdown --udid <UDID>
baguette screenshot --udid <UDID> --output /tmp/screen.jpg
baguette tap --udid <UDID> --x 219 --y 478 --width 438 --height 954
baguette swipe --udid <UDID> --startX 219 --startY 760 --endX 219 --endY 190 --width 438 --height 954
```

Coordinates are device points, not normalized percentages. Always pass the screen `width` and `height` in points for gesture commands.

## Integration Tests

Use Baguette as the host-side driver around a simulator build:

1. Build the app for simulator with the repo's normal script or `xcodebuild`.
2. Pick or create a simulator UDID.
3. Boot with Baguette.
4. Install and launch with `xcrun simctl`.
5. Drive flows with Baguette gestures.
6. Verify by screenshots, app logs, backend state, deterministic test hooks, or accessibility tools.
7. Shut down or erase the simulator when the test owns its state.

Template:

```bash
UDID="$(baguette list --json | jq -r '.available[0].udid')"
baguette boot --udid "$UDID"
xcrun simctl install "$UDID" path/to/App.app
xcrun simctl launch "$UDID" com.example.app
baguette screenshot --udid "$UDID" --output /tmp/launch.jpg
baguette tap --udid "$UDID" --x 219 --y 478 --width 438 --height 954
baguette screenshot --udid "$UDID" --output /tmp/after-tap.jpg
```

For repeated gestures, prefer one persistent process:

```bash
baguette input --udid "$UDID"
```

Send newline-delimited JSON:

```json
{"type":"tap","x":219,"y":478,"width":438,"height":954,"duration":0.05}
{"type":"swipe","startX":219,"startY":760,"endX":219,"endY":190,"width":438,"height":954,"duration":0.3}
```

## What To Keep Elsewhere

Do not use Baguette as the sole quality gate for:

- camera, photos, HealthKit, Bluetooth, notifications, background execution, Sign in with Apple, RevenueCat/StoreKit purchase edges, or other hardware/system-bound flows
- release readiness
- unit-level business logic

Keep Swift Testing/XCTest for logic and view models. Use real devices or TestFlight for hardware, entitlement, auth, and purchase-critical behavior.

## Failure Handling

If `baguette serve` or gestures fail:

1. Recheck `xcodebuild -version` and `xcode-select -p`.
2. Re-run `baguette list --json` to verify it can see simulators.
3. Try `baguette screenshot --udid <UDID>` before debugging gesture input.
4. If Baguette fails after an Xcode update, assume private-framework drift before changing app code.
5. Fall back to the existing iOS simulator tools for semantic accessibility navigation when Baguette only needs to provide screenshots or boot/stream.
