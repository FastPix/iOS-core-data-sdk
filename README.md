
# Introduction:

**FastPix Video Data Core SDK** for iOS is the official Swift-based SDK designed for integration with iOS supported video players. It serves as a foundation for collecting and processing player analytics when used with FastPix supported iOS Player Analytics SDKs. This SDK facilitates the gathering of video performance metrics, which can be accessed on the FastPix dashboard for monitoring and analysis. While the SDK is developed in Swift, the currently published SPM package includes only Swift support.

# Key Features:

- **Track Viewer Engagement:** Gain insights into how users interact with your videos.
- **Monitor Playback Quality:** Ensure video streaming by monitoring real-time metrics, including bitrate, buffering, startup performance, render quality, and playback failure errors.
- **Error Management:** Identify and resolve playback failures quickly with detailed error reports.
- **Customizable Tracking:** Flexible configuration to match your specific monitoring needs.
- **Centralized Dashboard:** Visualize and compare metrics on the [FastPix dashboard](https://dashboard.fastpix.com) to make data-driven decisions.
- **Compatible with tvOS:** Monitor and track video playback and analytics specifically on Apple TV, just like on iOS.

# Step 1: Installation and Setup:

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

# Step 2: Basic Integration

To integrate the SDK into your project, follow these steps:

## Import the SDK:

First, import the SDK into your Swift project:

```swift
import FastpixiOSVideoDataCore
```

##  Initialize and Configure the SDK:

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
## Dispatch Events:

As the player's state changes, call `dispatch` to report events to FastPix. It takes:

- `key` — the same player identifier you passed to `configure`.
- `event` — the event type supported by FastPix.
- `metadata` — additional parameters related to the event (`[:]` if none).

```swift
fpMetrix.dispatch(key: "player1", event: "EVENT_NAME", metadata: eventMetadata)
```
## Example Usage:

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
