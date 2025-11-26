# FastPix Video Data Core SDK - Documentation PR

## Documentation Changes

### What Changed
- [ ] New documentation added
- [ ] Existing documentation updated
- [ ] Documentation errors fixed
- [ ] Code examples updated
- [ ] Links and references updated

### Files Modified
- [ ] README.md
- [ ] docs/ files
- [ ] USAGE.md
- [ ] CONTRIBUTING.md
- [ ] Other: _______________

### Summary
**Brief description of changes:**

<!-- Describe what documentation was added, updated, or fixed for the iOS SDK -->

### Code Examples
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
            "video_id": "VIDEO_ID",           // Unique identifier for the video
            "workspace_id": "WORKSPACE_KEY",  // Workspace ID for analytics tracking
            "player_name": "Sample Player"    // Name of the video player
        ]
    ]
)

// Dispatch sample events
fpMetrix.dispatchEvent(event: "playing", metadata: [:])
fpMetrix.dispatchEvent(event: "pause", metadata: [:])
fpMetrix.dispatchEvent(event: "seeking", metadata: [:])
fpMetrix.dispatchEvent(event: "ended", metadata: [:])
fpMetrix.dispatchEvent(event: "buffering", metadata: [:])
fpMetrix.dispatchEvent(event: "error", metadata: ["player_error_code": "404", "player_error_message": "Video not found"])
```

### Testing
- [ ] All code examples tested on iOS
- [ ] Links verified
- [ ] Grammar checked
- [ ] Formatting consistent

### Review Checklist
- [ ] Content is accurate
- [ ] Code examples work as expected
- [ ] Links are working
- [ ] Grammar is correct
- [ ] Formatting is consistent

---

**Ready for review!**
