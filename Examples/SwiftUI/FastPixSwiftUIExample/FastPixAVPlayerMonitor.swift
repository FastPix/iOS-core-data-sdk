import AVKit
import FastpixiOSVideoDataCore
import Foundation

/// Bridges an `AVPlayer` to the FastPix Data (core) SDK.
///
/// The core SDK is player-agnostic: it does not observe a player itself. You
/// feed it two closures (playhead time + current video state) at `configure`
/// time, then `dispatch` playback events as the player's state changes. This
/// class does exactly that for `AVPlayer`.
///
/// Copy this file into your own app and construct one monitor per player.
final class FastPixAVPlayerMonitor {

    private let metrix = FastpixMetrix()
    private let playerKey = UUID().uuidString
    private weak var player: AVPlayer?

    private var observers: [NSKeyValueObservation] = []
    private var notificationTokens: [NSObjectProtocol] = []

    private var didStartPlay = false
    private var lastTimeControlStatus: AVPlayer.TimeControlStatus?

    /// - Parameters:
    ///   - player: the AVPlayer the app created and owns.
    ///   - metadata: the `data` dictionary sent with every beacon. Must include
    ///     `workspace_id`; `video_title` / `video_id` are recommended.
    init(player: AVPlayer, metadata: [String: Any]) {
        self.player = player

        metrix.configure(
            key: playerKey,
            passableMetadata: ["data": metadata],
            fetchPlayheadTime: { [weak player] in
                guard let seconds = player?.currentTime().seconds, seconds.isFinite else { return 0 }
                return Int(seconds * 1000)
            },
            fetchVideoState: { [weak self] in self?.currentVideoState() ?? [:] }
        )

        attachObservers(to: player)
    }

    deinit { detach() }

    /// Removes every observer and quiesces the SDK's internal pulse timer.
    /// Call from `.onDisappear` (SwiftUI) or `viewDidDisappear`/`deinit` (UIKit).
    func detach() {
        observers.forEach { $0.invalidate() }
        observers.removeAll()
        notificationTokens.forEach { NotificationCenter.default.removeObserver($0) }
        notificationTokens.removeAll()
        // A final "pause" lets the SDK's pulse timer stop rescheduling itself.
        metrix.dispatch(key: playerKey, event: "pause", metadata: [:])
    }

    // MARK: - Observation

    private func attachObservers(to player: AVPlayer) {
        observers.append(player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            self?.handleTimeControlStatus(player.timeControlStatus)
        })

        observers.append(player.observe(\.currentItem?.status, options: [.new]) { [weak self] player, _ in
            switch player.currentItem?.status {
            case .readyToPlay: self?.dispatch("playerReady")
            case .failed: self?.dispatchError(player.currentItem?.error)
            default: break
            }
        })

        observers.append(player.observe(\.currentItem?.isPlaybackBufferEmpty, options: [.new]) { [weak self] player, _ in
            if player.currentItem?.isPlaybackBufferEmpty == true { self?.dispatch("buffering") }
        })

        observers.append(player.observe(\.currentItem?.isPlaybackLikelyToKeepUp, options: [.new]) { [weak self] player, _ in
            if player.currentItem?.isPlaybackLikelyToKeepUp == true { self?.dispatch("buffered") }
        })

        observe(.AVPlayerItemDidPlayToEndTime) { [weak self] _ in self?.dispatch("ended") }
        observe(.AVPlayerItemTimeJumped) { [weak self] _ in
            self?.dispatch("seeking")
            self?.dispatch("seeked")
        }
        observe(.AVPlayerItemNewAccessLogEntry) { [weak self] _ in self?.handleAccessLog() }
        observe(.AVPlayerItemFailedToPlayToEndTime) { [weak self] note in
            self?.dispatchError(note.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error)
        }
    }

    private func observe(_ name: Notification.Name, _ handler: @escaping (Notification) -> Void) {
        notificationTokens.append(
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main, using: handler)
        )
    }

    private func handleTimeControlStatus(_ status: AVPlayer.TimeControlStatus) {
        guard status != lastTimeControlStatus else { return }
        lastTimeControlStatus = status

        switch status {
        case .playing:
            if !didStartPlay {
                didStartPlay = true
                dispatch("play") // triggers viewBegin inside the SDK
            }
            dispatch("playing")
        case .paused:
            dispatch("pause")
        case .waitingToPlayAtSpecifiedRate:
            if !didStartPlay {
                didStartPlay = true
                dispatch("play")
            }
            dispatch("buffering")
        @unknown default:
            break
        }
    }

    private func handleAccessLog() {
        guard let event = player?.currentItem?.accessLog()?.events.last else { return }
        let bitrate = event.indicatedBitrate > 0 ? event.indicatedBitrate : event.observedBitrate
        guard bitrate > 0 else { return }
        dispatch("variantChanged", metadata: ["video_source_bitrate": Int(bitrate)])
    }

    private func dispatchError(_ error: Error?) {
        dispatch("error", metadata: [
            "player_error_code": (error as NSError?)?.code ?? -1,
            "player_error_message": error?.localizedDescription ?? "Unknown playback error"
        ])
    }

    private func dispatch(_ event: String, metadata: [String: Any] = [:]) {
        metrix.dispatch(key: playerKey, event: event, metadata: metadata)
    }

    // MARK: - Video state

    private func currentVideoState() -> [String: Any] {
        guard let player else { return [:] }
        let item = player.currentItem
        let presentationSize = item?.presentationSize ?? .zero
        let duration = item?.duration.seconds ?? .nan

        var state: [String: Any] = [
            "player_is_paused": player.timeControlStatus == .paused,
            "player_autoplay_on": false
        ]
        if let url = (item?.asset as? AVURLAsset)?.url.absoluteString {
            state["video_source_url"] = url
            state["player_source_url"] = url
        }
        if presentationSize.width > 0 {
            state["video_source_width"] = Int(presentationSize.width)
            state["video_source_height"] = Int(presentationSize.height)
        }
        if duration.isFinite, duration > 0 {
            state["video_source_duration"] = Int(duration * 1000)
        }
        return state
    }
}
