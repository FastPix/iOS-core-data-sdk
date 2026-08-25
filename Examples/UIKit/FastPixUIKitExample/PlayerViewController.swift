import AVKit
import UIKit

/// UIKit demo. The AVPlayer and the FastPix monitor live for the view
/// controller's lifetime; teardown happens in `deinit`.
final class PlayerViewController: UIViewController {
    private let avPlayer = AVPlayer(url: Config.streamURL)
    private let playerController = AVPlayerViewController()
    private var monitor: FastPixAVPlayerMonitor?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "UIKit Player"
        view.backgroundColor = .systemBackground

        monitor = FastPixAVPlayerMonitor(
            player: avPlayer,
            metadata: Config.metadata(
                videoTitle: "UIKit Sample",
                videoId: "uikit-sample",
                playerName: "UIKit AVPlayerViewController"
            )
        )

        playerController.player = avPlayer
        addChild(playerController)
        playerController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playerController.view)
        NSLayoutConstraint.activate([
            playerController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerController.view.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            playerController.view.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 9.0 / 16.0)
        ])
        playerController.didMove(toParent: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        avPlayer.play()
    }

    deinit {
        avPlayer.pause()
        monitor?.detach()
    }
}
