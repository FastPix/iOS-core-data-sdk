# Changelog

All notable changes to this project will be documented in this file.

## [1.0.4]
- Added support for tvOS, enabling all existing features including engagement tracking, playback quality monitoring, error reporting, and custom metadata on Apple TV.
- Enhanced device details parameters to accurately capture and report tvOS specific device information alongside existing metrics.

## [1.0.3]
- Implemented deinit to remove notification observers when the player is deinitialized, ensuring proper resource cleanup.

## [1.0.2]
- Fixed video_source_bitrate in variantChanged events.
- Fixed event transition calculations .

## [1.0.1]
- Fixed bugs and improved the accuracy of metrics parameter calculations during event transitions.

## [1.0.0]

### Added
  - Enabled video performance tracking using FastPix Data SDK, supporting user engagement metrics, playback quality monitoring, and real-time streaming diagnostics.
  - Provides robust error management and reporting capabilities for video performance tracking.
  - Includes support for custom metadata, enabling users to pass optional fields such as `video_id`, `video_title`, `video_duration`, and more.
  - Introduced event tracking for `videoChange` to handle metadata updates during playback transitions.
