import Foundation

/// The two values you must set to see data in your dashboard.
///
/// The values below are a shared FastPix TEST workspace and a public sample
/// stream — fine for trying the example out. Swap in your own workspace key
/// (dashboard.fastpix.com → Workspaces) and stream URL for real integration.
enum Config {

    /// FastPix workspace ID. Identifies the analytics workspace beacons land in.
    static let workspaceId = "1177266527498207235"

    /// HLS stream to play.
    static let streamURL = URL(string: "https://stream.fastpix.com/7c8d5087-edf7-462f-a1b3-e2fbd30747fa.m3u8")!

    /// Beacon metadata. `workspace_id` is required.
    static func metadata(videoTitle: String, videoId: String, playerName: String) -> [String: Any] {
        [
            "workspace_id": workspaceId,
            "video_title": videoTitle,
            "video_id": videoId,
            "player_name": playerName
        ]
    }
}
