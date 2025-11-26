---
name: Bug Report
about: Report an issue related to the FastPix iOS Video Data Core SDK
title: '[BUG] '
labels: bug
assignees: ''
---

## Bug Description
A clear and concise description of what the bug is.

---

## Reproduction Steps

### 1. **SDK Setup**

Add the FastPix iOS Data Core SDK using Swift Package Manager:

```
https://github.com/FastPix/iOS-core-data-sdk.git
```

Import the library:

```swift
import FastpixiOSVideoDataCore
```

### 2. **Code To Reproduce**

Provide a minimal reproducible code snippet. Example:

```swift
import FastpixiOSVideoDataCore

let fpMetrix = FastpixMetrix()

fpMetrix.configure(
    "player1",
    [
        "data": [
            "video_title": "NEW_VIDEO",
            "video_id": "VIDEO_ID",
            "workspace_id": "WORKSPACE_KEY",
            "player_name": "Sample Player"
        ]
    ]
)

// Example event dispatching
fpMetrix.dispatchEvent(event: "playing", metadata: [:])
fpMetrix.dispatchEvent(event: "pause", metadata: [:])
fpMetrix.dispatchEvent(event: "buffering", metadata: [:])
fpMetrix.dispatchEvent(event: "error", metadata: ["player_error_code": "404"])
```

Replace the above snippet with the exact code where the issue occurs.

---

## Expected Behavior
```
<!-- Describe what you expected to happen -->
```

## Actual Behavior
```
<!-- Describe what actually happened -->
```

---

## Environment

- **SDK Version**: [e.g., 1.0.3]
- **iOS Version**: [e.g., iOS 17.2]
- **Device/Simulator**: [e.g., iPhone 14 Pro, Xcode Simulator]
- **Xcode Version**: [e.g., 15.3]
- **Integration Method**: Swift Package Manager (SPM) / Manual
- **Player Type**: [AVPlayer, Custom Player, etc.]

---

## Code Sample
```swift
// Provide a minimal reproducible sample
```

## Logs / Errors / Stack Trace
```
Paste console logs, crash logs, or SDK error responses here
```

---

## Additional Context
Add any other context that would help us investigate the issue.

## Screenshots / Screen Recording
If applicable, attach screenshots or a video showing the problem.
