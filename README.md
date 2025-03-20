
# Introduction:

**FastPix Video Data Core SDK** for iOS is the official Swift-based SDK designed for integration with iOS supported video players. It serves as a foundation for collecting and processing player analytics when used with FastPix supported iOS Player Analytics SDKs. This SDK facilitates the gathering of video performance metrics, which can be accessed on the FastPix dashboard for monitoring and analysis. While the SDK is developed in Swift, the currently published SPM package includes only Swift support.

# Key Features:

- **Track Viewer Engagement:** Gain insights into how users interact with your videos.
- **Monitor Playback Quality:** Ensure video streaming by monitoring real-time metrics, including bitrate, buffering, startup performance, render quality, and playback failure errors.
- **Error Management:** Identify and resolve playback failures quickly with detailed error reports.
- **Customizable Tracking:** Flexible configuration to match your specific monitoring needs.
- **Centralized Dashboard:** Visualize and compare metrics on the [FastPix dashboard](https://dashboard.fastpix.io) to make data-driven decisions.

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

Create an instance of FastpixMetrix and configure it with a unique player ID to track each player instance individually. The configuration method also accepts metadata as a second argument to provide additional details about the video.

```swift
let fpMetrix = FastpixMetrix()

fpMetrix.configure(
    "player1",  // Unique player identifier
    [
        "data": [
            "video_title": "NEW_VIDEO",       // Title of the video being played
            "video_id": "VIDEO_ID",         // Unique identifier for the video
            "workspace_id": "WORKSPACE_KEY",  // Workspace ID for analytics tracking
            "player_name": "Sample Player"    // Name of the video player
        ]
    ]
)
```
## Dispatch Events:

The SDK allows you to track various player-related events supported by FastPix using the dispatch function. It accepts two arguments:

- Event Name: The event type supported by FastPix.
- Event Metadata: Additional parameters related to the event.

```swift
fpMetrix.dispatch("EVENT_NAME", eventMetadata)
```
## Example Usage:

```swift
import FastpixiOSVideoDataCore

// Initialize FastpixMetrix instance for tracking video analytics
let fpMetrix = FastpixMetrix()

// Configure FastpixMetrix with a unique player identifier and metadata
fpMetrix.configure(
    "player1",  // Unique player identifier
    [   
        "data": [
            "video_title": "NEW_VIDEO",       // Title of the video being played
            "video_id": "VIDEO_ID",         // Unique identifier for the video
            "workspace_id": "WORKSPACE_KEY",  // Workspace ID for analytics tracking
            "player_name": "Sample Player"    // Name of the video player
        ]
    ]
)

// MARK: - Event Dispatching
// Fastpix supports various events such as: 
// ["playerReady", "viewStart", "play", "playing", "pause", "seeking", "seeked", "buffering", "buffered", 
//  "variantChanged", "error", "requestCompleted", "requestFailed", "ended", "viewCompleted", "videoChange"]

// Dispatches event when video starts playing
fpMetrix.dispatchEvent(event: "playing", metadata: [:]) 

// Dispatches event when the video is paused
fpMetrix.dispatchEvent(event: "pause", metadata: [:])

// Dispatches event when the user seeks to a different position in the video
fpMetrix.dispatchEvent(event: "seeking", metadata: [:])

// Additional example: Dispatch event when video ends
fpMetrix.dispatchEvent(event: "ended", metadata: [:])

// Additional example: Dispatch event when buffering starts
fpMetrix.dispatchEvent(event: "buffering", metadata: [:])

// Additional example: Dispatch event when playback error occurs (you can pass error details in metadata)
fpMetrix.dispatchEvent(event: "error", metadata: ["player_error_code": "404", "player_error_message": "Video not found"])
```
