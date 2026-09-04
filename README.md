# FastPix Video Data Core SDK for iOS - player analytics core (Swift)

[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-brightgreen?logo=swift)](https://swift.org/package-manager/)
[![Swift](https://img.shields.io/badge/Swift-5.9-F05138?logo=swift&logoColor=white)](https://swift.org)
[![Platform: iOS | tvOS](https://img.shields.io/badge/platform-iOS%20%7C%20tvOS-000000?logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![Latest release](https://img.shields.io/github/v/release/FastPix/iOS-core-data-sdk?sort=semver)](https://github.com/FastPix/iOS-core-data-sdk/releases)
[![license](https://img.shields.io/github/license/FastPix/iOS-core-data-sdk)](https://github.com/FastPix/iOS-core-data-sdk/blob/main/LICENSE)

**FastPix Video Data Core SDK** for iOS is the official Swift-based SDK designed for integration with iOS supported video players. It serves as a foundation for collecting and processing player analytics when used with FastPix supported iOS Player Analytics SDKs. This SDK facilitates the gathering of video performance metrics, which can be accessed on the FastPix dashboard for monitoring and analysis. While the SDK is developed in Swift, the currently published SPM package includes only Swift support.

**Works with:** iOS · tvOS · Swift 5.9 · Swift Package Manager · player-agnostic (any AVPlayer-based player)

📖 **Docs:** https://fastpix.com/docs/ios-and-cross-platform-players/monitor-avplayer &nbsp;·&nbsp; 🚀 **Dashboard:** https://dashboard.fastpix.com

## Key Features

- **Track Viewer Engagement:** Gain insights into how users interact with your videos.
- **Monitor Playback Quality:** Ensure video streaming by monitoring real-time metrics, including bitrate, buffering, startup performance, render quality, and playback failure errors.
- **Error Management:** Identify and resolve playback failures quickly with detailed error reports.
- **Customizable Tracking:** Flexible configuration to match your specific monitoring needs.
- **Centralized Dashboard:** Visualize and compare metrics on the [FastPix dashboard](https://dashboard.fastpix.com) to make data-driven decisions.
- **Compatible with tvOS:** Monitor and track video playback and analytics specifically on Apple TV, just like on iOS.

## Start here

If you are using the FastPix Video Data Core SDK for the first time, follow these steps in order:

1. [Install the SDK](#install-the-sdk)
2. [Get your Workspace Key](#get-your-workspace-key)
3. [Import the SDK](#import-the-sdk)
4. [Configure the SDK](#configure-the-sdk)
5. [Dispatch events](#dispatch-events)
6. [See a complete example](#complete-example)
7. [Verify your integration](#verify-your-integration)
8. [Understand the data flow](#understand-the-data-flow)

Do not skip the verification steps. If an install, workspace-key, or configuration problem occurs, fix it before continuing.

---

### Before you begin

To use the SDK, make sure you have:

- **Xcode 15 or later** (the package uses `swift-tools-version: 5.9`), and an iOS (or tvOS) app with a video player (typically `AVPlayer`).
- A **FastPix account** and a **Workspace Key** (see [Get your Workspace Key](#get-your-workspace-key)).
- A way to read your player's **playhead time** (in milliseconds) and **video state** - the SDK reads these through two closures you provide.

> **Using AVPlayer?** This is the low-level core SDK. If you play with `AVPlayer`, the ready-made [iOS-data-avplayer-sdk](https://github.com/FastPix/iOS-data-avplayer-sdk) wraps this core and wires AVPlayer for you - most apps should start there.

---

## Install the SDK

To get started with this SDK, you can integrate it into your project using **Swift Package Manager (SPM)**. Follow these steps to add the package to your iOS project.

1. **Open your Xcode project** and navigate to:
   ```
   File → Add Packages…
   ```

2. **Enter the repository URL** for the FastPix SDK:
   ```
   https://github.com/FastPix/iOS-core-data-sdk.git
   ```

3. **Choose the latest stable version** and click `Add Package`.

4. **Select the target** where you want to use the SDK and click `Add Package`.

## Get your Workspace Key

The SDK tags analytics with your **Workspace Key**, which you pass as `workspace_id` in the metadata.

1. Log in to the [FastPix Dashboard](https://dashboard.fastpix.com) and open the **Workspaces** section.
2. Copy your **Workspace Key** and use it as the `workspace_id` value in `passableMetadata` (see [Configure the SDK](#configure-the-sdk)).

Learn more in [Set up a workspace](https://fastpix.com/docs/getting-started/set-up-a-workspace).

## Import the SDK

First, import the SDK into your Swift project:

```swift
import FastpixiOSVideoDataCore
```

## Configure the SDK

Create an instance of `FastpixMetrix` and `configure` it. The SDK is
**player-agnostic** — it does not observe a player itself. You supply:

- `key` — a unique identifier per player instance (so you can track several at once).
- `passableMetadata` — a `["data": [...]]` dictionary describing the video and workspace.
- `fetchPlayheadTime` — a closure returning the current playhead position **in milliseconds** (`Int`).
- `fetchVideoState` — a closure returning the current video state as `[String: Any]`.

```swift
let fpMetrix = FastpixMetrix()

fpMetrix.configure(
    key: "player1",  // Unique player identifier
    passableMetadata: [
        "data": [
            "video_title": "NEW_VIDEO",       // Title of the video being played
            "video_id": "VIDEO_ID",           // Unique identifier for the video
            "workspace_id": "WORKSPACE_KEY",  // Workspace ID for analytics tracking
            "player_name": "Sample Player"    // Name of the video player
        ]
    ],
    fetchPlayheadTime: {
        // Return the player's current position in milliseconds.
        Int(player.currentTime().seconds * 1000)
    },
    fetchVideoState: {
        // Return the current video state. Recognized keys include:
        // video_source_url, video_source_width, video_source_height,
        // video_source_duration (ms), player_width, player_height,
        // player_is_paused, player_autoplay_on.
        [
            "player_is_paused": player.timeControlStatus == .paused,
            "video_source_url": "https://.../stream.m3u8"
        ]
    }
)
```
## Dispatch events

As the player's state changes, call `dispatch` to report events to FastPix. It takes:

- `key` — the same player identifier you passed to `configure`.
- `event` — the event type supported by FastPix.
- `metadata` — additional parameters related to the event (`[:]` if none).

```swift
fpMetrix.dispatch(key: "player1", event: "EVENT_NAME", metadata: eventMetadata)
```
## Complete example

```swift
import FastpixiOSVideoDataCore

// Initialize FastpixMetrix instance for tracking video analytics
let fpMetrix = FastpixMetrix()

// Configure FastpixMetrix with a unique player identifier, metadata and the
// two state closures the SDK reads from your player.
fpMetrix.configure(
    key: "player1",  // Unique player identifier
    passableMetadata: [
        "data": [
            "video_title": "NEW_VIDEO",       // Title of the video being played
            "video_id": "VIDEO_ID",           // Unique identifier for the video
            "workspace_id": "WORKSPACE_KEY",  // Workspace ID for analytics tracking
            "player_name": "Sample Player"    // Name of the video player
        ]
    ],
    fetchPlayheadTime: { Int(player.currentTime().seconds * 1000) },
    fetchVideoState: { ["player_is_paused": player.timeControlStatus == .paused] }
)

// MARK: - Event Dispatching
// Fastpix supports various events such as:
// ["playerReady", "play", "playing", "pause", "seeking", "seeked", "buffering", "buffered",
//  "variantChanged", "error", "requestCompleted", "requestFailed", "ended", "videoChange"]

// Dispatches event when video starts playing
fpMetrix.dispatch(key: "player1", event: "playing", metadata: [:])

// Dispatches event when the video is paused
fpMetrix.dispatch(key: "player1", event: "pause", metadata: [:])

// Dispatches event when the user seeks to a different position in the video
fpMetrix.dispatch(key: "player1", event: "seeking", metadata: [:])

// Additional example: Dispatch event when video ends
fpMetrix.dispatch(key: "player1", event: "ended", metadata: [:])

// Additional example: Dispatch event when buffering starts
fpMetrix.dispatch(key: "player1", event: "buffering", metadata: [:])

// Additional example: Dispatch event when playback error occurs (you can pass error details in metadata)
fpMetrix.dispatch(key: "player1", event: "error", metadata: ["player_error_code": "404", "player_error_message": "Video not found"])
```

> **Full working examples:** see [`Examples/`](Examples) for runnable UIKit and
> SwiftUI apps that wire an `AVPlayer` to this SDK end to end.
## Verify your integration

Run your app and play a video. As the player changes state and you call `dispatch`, the SDK sends analytics beacons to FastPix. To confirm it is working:

1. Play the video and let a few events fire (`playing`, `pause`, `seeking`, `ended`).
2. Open the [FastPix Dashboard](https://dashboard.fastpix.com) and go to **Video Data → Views**.
3. After a short delay, a new view/session should appear for the workspace whose Workspace Key you used, showing playback metrics for the video (identified by the `video_title` / `video_id` you passed).

If nothing appears, check that:

- Your `workspace_id` is the correct Workspace Key for that workspace.
- `configure` was called (with a given `key`) before you `dispatch` events using the same `key`.
- `fetchPlayheadTime` returns the position in milliseconds, and `fetchVideoState` returns a non-empty state dictionary.
- The device has network access.

## Understand the data flow

The SDK is **player-agnostic**: you configure it with your player's identity and two closures that read the current playhead time and video state, then dispatch events as the player's state changes. The SDK turns those into analytics beacons that appear on the FastPix dashboard.

![FastPix iOS Video Data flow: your video player reports playhead time and state to FastpixMetrix through configure and dispatch; the SDK sends analytics beacons to FastPix Video Data, which surfaces QoE metrics on the FastPix dashboard.](https://static.fastpix.com/ios-core-data-workflow.png)

## Supported events

Dispatch these event names as your player's state changes (pass `[:]` for `metadata` when there are no extra fields):

`playerReady`, `play`, `playing`, `pause`, `seeking`, `seeked`, `buffering`, `buffered`, `variantChanged`, `error`, `requestCompleted`, `requestFailed`, `ended`, `videoChange`.

For `error`, pass details in `metadata` (for example `["player_error_code": "404", "player_error_message": "Video not found"]`). Use `videoChange` when the same player loads a new video.

## FAQ

**What is this SDK for?**
It collects video playback analytics (QoE) from an iOS player and reports them to the FastPix dashboard. See [Key Features](#key-features).

**Which package do I install?**
Add `https://github.com/FastPix/iOS-core-data-sdk.git` in Xcode, then `import FastpixiOSVideoDataCore`. See [Install the SDK](#install-the-sdk).

**I use AVPlayer - do I need this directly?**
Usually no. Use [iOS-data-avplayer-sdk](https://github.com/FastPix/iOS-data-avplayer-sdk), which wraps this core and wires AVPlayer for you. This core SDK is for custom or non-AVPlayer players.

**Where do I get my Workspace Key?**
From the Workspaces section of the [FastPix Dashboard](https://dashboard.fastpix.com). See [Get your Workspace Key](#get-your-workspace-key).

**How does the SDK read player state?**
You provide two closures at `configure` time: `fetchPlayheadTime` (current position in ms) and `fetchVideoState` (a state dictionary). The SDK does not observe the player itself. See [Configure the SDK](#configure-the-sdk).

**Which events can I dispatch?**
See [Supported events](#supported-events).

**Is there runnable example code?**
Yes - UIKit and SwiftUI AVPlayer examples under [`Examples/`](Examples).

## Which FastPix repo do I need?

This is the low-level analytics core. Most integrations use a higher-level SDK:

| I want to... | Repo |
|---|---|
| Add analytics to an AVPlayer app (wraps this core) | [iOS-data-avplayer-sdk](https://github.com/FastPix/iOS-data-avplayer-sdk) |
| Play FastPix video in an iOS app | [iOS-player](https://github.com/FastPix/iOS-player) |
| Collect playback analytics on Roku | [Roku-data-core-SDK](https://github.com/FastPix/Roku-data-core-SDK) |
| Play FastPix video on the web | [web-player-component](https://github.com/FastPix/web-player-component) |
| Add resumable uploads to an iOS app | [iOS-Uploads](https://github.com/FastPix/iOS-Uploads) |

Browse everything in the [FastPix organization](https://github.com/orgs/FastPix/repositories).

## References

- **Monitor AVPlayer (iOS and tvOS)**: [fastpix.com/docs/ios-and-cross-platform-players/monitor-avplayer](https://fastpix.com/docs/ios-and-cross-platform-players/monitor-avplayer)
- **Pass custom metadata to metrics**: [fastpix.com/docs/working-with-video-data/pass-custom-metadata-to-metrics](https://fastpix.com/docs/working-with-video-data/pass-custom-metadata-to-metrics)
- **Set up a workspace**: [fastpix.com/docs/getting-started/set-up-a-workspace](https://fastpix.com/docs/getting-started/set-up-a-workspace)
- **AVPlayer analytics SDK (built on this core)**: [github.com/FastPix/iOS-data-avplayer-sdk](https://github.com/FastPix/iOS-data-avplayer-sdk)

## License

This SDK is released under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
