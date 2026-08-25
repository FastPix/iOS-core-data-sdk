# FastPix Data SDK — UIKit Example

An `AVPlayerViewController` with the FastPix Video Data Core SDK attached.

## Run

```bash
open FastPixUIKitExample.xcodeproj
```

Pick a Simulator (or your device), press **▶ Run**, then open
[dashboard.fastpix.com](https://dashboard.fastpix.com) → your workspace to watch
views appear. The project references the SDK as a local Swift package at
`../../`, so it builds against this checkout — no network fetch.

## Files

| File | Role |
|------|------|
| `FastPixAVPlayerMonitor.swift` | Maps `AVPlayer` state → the SDK's `configure`/`dispatch` calls. **Copy this into your app.** |
| `PlayerViewController.swift` | Creates the player, attaches the monitor, tears it down in `deinit`. |
| `Config.swift` | Your `workspaceId` + `streamURL`. Swap in your own to see your data. |
| `AppDelegate.swift` | App entry point (programmatic window, no storyboard). |

## Set your own workspace + stream

Edit `Config.swift`:

```swift
static let workspaceId = "1177266527498207235"          // shared TEST workspace
static let streamURL = URL(string: "https://stream.fastpix.com/....m3u8")!
```

Replace `workspaceId` (dashboard.fastpix.com → **Workspaces**) and `streamURL`
with your own. `workspace_id` is the only required beacon field.
