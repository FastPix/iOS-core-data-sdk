import AVKit
import SwiftUI

/// SwiftUI demo. The View struct is ephemeral, so the AVPlayer and the FastPix
/// monitor live in an ObservableObject that the View holds via `@StateObject`.
/// Teardown happens in `.onDisappear` — never in the View body.
struct PlayerScreen: View {
    @StateObject private var model = PlayerModel()

    var body: some View {
        VideoPlayer(player: model.player)
            .frame(maxWidth: .infinity)
            .aspectRatio(16 / 9, contentMode: .fit)
            .navigationTitle("SwiftUI Player")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { model.player.play() }
            .onDisappear { model.teardown() }
    }
}

@MainActor
final class PlayerModel: ObservableObject {
    let player: AVPlayer
    private let monitor: FastPixAVPlayerMonitor

    init() {
        player = AVPlayer(url: Config.streamURL)
        monitor = FastPixAVPlayerMonitor(
            player: player,
            metadata: Config.metadata(
                videoTitle: "SwiftUI Sample",
                videoId: "swiftui-sample",
                playerName: "SwiftUI VideoPlayer"
            )
        )
    }

    func teardown() {
        player.pause()
        monitor.detach()
    }
}
